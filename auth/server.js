'use strict';
const http = require('http');
const crypto = require('crypto');

const REQUIRED_VARS = ['JWT_SECRET', 'JWT_ISS', 'ADMIN_PASSWORD', 'TELLER_PASSWORD', 'EMPRESA_PASSWORD', 'CLIENTE_PASSWORD'];
const EMPRESA1_RUC = process.env.EMPRESA1_RUC || null;
const missing = REQUIRED_VARS.filter(v => !process.env[v]);
if (missing.length > 0) {
  console.error('[auth-service] FATAL: variables de entorno requeridas no definidas:', missing.join(', '));
  process.exit(1);
}

const JWT_SECRET = process.env.JWT_SECRET;
const JWT_ISS    = process.env.JWT_ISS;

// Build users map dynamically — empresa key IS the RUC so login works with RUC as username
const empresaKey = process.env.EMPRESA1_RUC || 'empresa1';
const USERS = process.env.AUTH_USERS
  ? JSON.parse(process.env.AUTH_USERS)
  : {
      admin:                { password: process.env.ADMIN_PASSWORD,   role: 'admin' },
      teller:               { password: process.env.TELLER_PASSWORD,  role: 'teller' },
      [empresaKey]:         { password: process.env.EMPRESA_PASSWORD, role: 'empresa' },
      cliente1:             { password: process.env.CLIENTE_PASSWORD, role: 'cliente' },
    };

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
    req.on('end', () => {
      try {
        const { username, password } = JSON.parse(body);
        const user = USERS[username];
        if (user && user.password === password) {
          const token = signJWT(username, user.role);
          res.writeHead(200);
          res.end(JSON.stringify({ token, type: 'Bearer', expiresIn: 3600, role: user.role }));
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
  console.log('[auth-service] Usuarios: ' + Object.keys(USERS).join(' / '));
});
