import http from 'node:http';

const server = http.createServer((request, response) => {
  if (request.url !== '/ppnet') {
    response.writeHead(404, { Connection: 'close' });
    response.end('NOT_FOUND');
    return;
  }
  response.writeHead(200, {
    'Content-Type': 'text/plain',
    'Content-Length': '13',
    Connection: 'close',
  });
  response.end('PPNET_HTTP_OK');
});

server.listen(18080, '0.0.0.0', () => {
  process.stdout.write('PPNET HTTP SERVER READY\n');
});
