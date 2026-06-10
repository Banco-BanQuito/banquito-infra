'use strict';
const http = require('http');
const crypto = require('crypto');

const JWT_SECRET = process.env.JWT_SECRET || 'banquito-jwt-secret-2024';
const JWT_ISS    = process.env.JWT_ISS    || 'banquito';

// Usuarios cargados desde variable de entorno AUTH_USERS (JSON) o defaults de demo
const USERS = process.env.AUTH_USERS
  ? JSON.parse(process.env.AUTH_USERS)
  : {
      admin:    { password: process.env.ADMIN_PASSWORD    || 'admin123',   role: 'admin' },
      teller:   { password: process.env.TELLER_PASSWORD   || 'teller123',  role: 'teller' },
      empresa1: { password: process.env.EMPRESA_PASSWORD  || 'empresa123', role: 'empresa' },
      cliente1: { password: process.env.CLIENTE_PASSWORD  || 'cliente123', role: 'cliente' },
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
