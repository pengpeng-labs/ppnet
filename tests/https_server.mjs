import { readFileSync } from 'node:fs';
import https from 'node:https';

const handler = (request, response) => {
  if (request.url !== '/secure') {
    response.writeHead(404, { Connection: 'close' });
    response.end('NOT_FOUND');
    return;
  }
  response.writeHead(200, {
    'Content-Type': 'text/plain',
    'Content-Length': '14',
    Connection: 'close',
  });
  response.end('PPNET_HTTPS_OK');
};

const tlsOptions = (name) => ({
  key: readFileSync(`build/test-pki/${name}.key`),
  cert: readFileSync(`build/test-pki/${name}.crt`),
  minVersion: 'TLSv1.2',
  maxVersion: 'TLSv1.2',
  ciphers: 'ECDHE-RSA-AES128-GCM-SHA256',
});

const trusted = https.createServer(tlsOptions('server'), handler);
const untrusted = https.createServer(tlsOptions('untrusted-server'), handler);
let ready = 0;
const announce = () => {
  ready += 1;
  if (ready === 2) process.stdout.write('PPNET HTTPS SERVER READY\n');
};

trusted.listen(18443, '0.0.0.0', announce);
untrusted.listen(18444, '0.0.0.0', announce);
