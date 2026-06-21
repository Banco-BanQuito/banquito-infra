'use strict';
const http = require('node:http');
const crypto = require('node:crypto');

const REQUIRED_VARS = ['JWT_SECRET', 'JWT_ISS'];
const missing = REQUIRED_VARS.filter(v => !process.env[v]);
if (missing.length > 0) {
  console.error('[auth-service] FATAL: variables de entorno requeridas no definidas:', missing.join(', '));
  process.exit(1);
}

const JWT_SECRET = process.env.JWT_SECRET;
const JWT_ISS    = process.env.JWT_ISS;

const ACCOUNT_CORE_URL = process.env.ACCOUNT_CORE_URL || 'http://account-core-service:8081';
const PARTY_SERVICE_URL = process.env.PARTY_SERVICE_URL || 'http://party-service:8083';

const STAFF_ROLE_MAP = { CAJERO: 'teller', OPERADOR: 'admin' };
const CUSTOMER_ROLE_MAP = { JURIDICO: 'empresa', NATURAL: 'cliente' };

function postJson(baseUrl, path, payload) {
  return new Promise((resolve, reject) => {
    const url = new URL(path, baseUrl);
    const body = JSON.stringify(payload);
    const req = http.request(
      {
        hostname: url.hostname,
        port: url.port,
        path: url.pathname,
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'Content-Length': Buffer.byteLength(body) },
        timeout: 5000,
      },
      (res) => {
        let data = '';
        res.on('data', (chunk) => { data += chunk; });
        res.on('end', () => {
          let parsed = {};
          try { parsed = data ? JSON.parse(data) : {}; } catch { parsed = {}; }
          resolve({ status: res.statusCode, body: parsed });
        });
      }
    );
    req.on('error', reject);
    req.on('timeout', () => req.destroy(new Error('timeout')));
    req.write(body);
    req.end();
  });
}

// Intenta autenticar al usuario primero como personal (cajero/operador) en
// account-core-service y, si no corresponde, como cliente/empresa en party-service.
// No hay datos de usuario hardcodeados: la validacion es completamente contra la base real.
async function authenticate(username, password) {
  try {
    const staffRes = await postJson(ACCOUNT_CORE_URL, '/api/v2/auth/login/staff', { username, password });
    if (staffRes.status === 200) {
      const role = STAFF_ROLE_MAP[staffRes.body.role] || staffRes.body.role;
      return { sub: staffRes.body.username, role };
    }
  } catch (err) {
    console.error('[auth-service] account-core-service no disponible:', err.message);
  }

  try {
    const customerRes = await postJson(PARTY_SERVICE_URL, '/api/v2/auth/login', { username, password });
    if (customerRes.status === 200) {
      const role = CUSTOMER_ROLE_MAP[customerRes.body.customerType] || 'cliente';
      return { sub: customerRes.body.username, role, mustChangePassword: customerRes.body.mustChangePassword };
    }
  } catch (err) {
    console.error('[auth-service] party-service no disponible:', err.message);
  }

  return null;
}

function b64url(obj) {
  return Buffer.from(JSON.stringify(obj)).toString('base64url');
}

function signJWT(sub, role) {
  const now = Math.floor(Date.now() / 1000);
  const header  = b64url({ alg: 'HS256', typ: 'JWT' });
  const payload = b64url({ iss: JWT_ISS, sub, role, iat: now, exp: now + 3600 });
  const sig = crypto
    .createHmac('sha256', JWT_SECRET)
    .update(`${header}.${payload}`)
    .digest('base64url');
  return `${header}.${payload}.${sig}`;
}

function setCors(res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
}

const server = http.createServer((req, res) => {
  res.setHeader('Content-Type', 'application/json');
  setCors(res);

  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }

  if (req.method === 'POST' && req.url === '/api/v2/auth/login') {
    let body = '';
    req.on('data', (chunk) => { body += chunk; });
    req.on('end', async () => {
      try {
        const { username, password } = JSON.parse(body);
        const authResult = await authenticate(username, password);
        if (authResult) {
          const token = signJWT(authResult.sub, authResult.role);
          res.writeHead(200);
          res.end(JSON.stringify({
            token,
            type: 'Bearer',
            expiresIn: 3600,
            role: authResult.role,
            mustChangePassword: authResult.mustChangePassword ?? false,
          }));
        } else {
          res.writeHead(401);
          res.end(JSON.stringify({ error: 'Credenciales inválidas' }));
        }
      } catch {
        res.writeHead(400);
        res.end(JSON.stringify({ error: 'JSON inválido' }));
      }
    });
    return;
  }

  if (req.method === 'GET' && req.url === '/health') {
    res.writeHead(200);
    res.end(JSON.stringify({ status: 'UP', service: 'auth-service' }));
    return;
  }

  res.writeHead(404);
  res.end(JSON.stringify({ error: 'Not found' }));
});

server.listen(8090, () => {
  console.log('[auth-service] Puerto 8090');
  console.log('[auth-service] Delegando autenticación a:', ACCOUNT_CORE_URL, 'y', PARTY_SERVICE_URL);
});
