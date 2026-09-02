#!/bin/sh
set -eu

root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
destination="$root/build/test-pki"
third_party=${THIRD_PARTY_BUILD:-"$root/build/third_party"}
HOST_CC=${HOST_CC:-cc}
HOST_AR=${HOST_AR:-ar}
bearssl_source=$(cat "$third_party/bearssl.path")
mkdir -p "$destination"

openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 \
    -out "$destination/ca.key" 2>/dev/null
openssl req -new -x509 -sha256 -days 2 -key "$destination/ca.key" \
    -subj '/CN=ppnet test CA' \
    -addext 'basicConstraints=critical,CA:TRUE' \
    -addext 'keyUsage=critical,keyCertSign,cRLSign' \
    -out "$destination/ca.crt"
openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 \
    -out "$destination/server.key" 2>/dev/null
openssl req -new -sha256 -key "$destination/server.key" \
    -subj '/CN=ppnet.test' -out "$destination/server.csr"
openssl x509 -req -sha256 -days 1 -in "$destination/server.csr" \
    -CA "$destination/ca.crt" -CAkey "$destination/ca.key" -CAcreateserial \
    -extfile "$root/tests/server-ext.cnf" -out "$destination/server.crt" \
    2>/dev/null

openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 \
    -out "$destination/untrusted-ca.key" 2>/dev/null
openssl req -new -x509 -sha256 -days 2 \
    -key "$destination/untrusted-ca.key" \
    -subj '/CN=ppnet untrusted test CA' \
    -addext 'basicConstraints=critical,CA:TRUE' \
    -addext 'keyUsage=critical,keyCertSign,cRLSign' \
    -out "$destination/untrusted-ca.crt"
openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 \
    -out "$destination/untrusted-server.key" 2>/dev/null
openssl req -new -sha256 -key "$destination/untrusted-server.key" \
    -subj '/CN=ppnet.test' -out "$destination/untrusted-server.csr"
openssl x509 -req -sha256 -days 1 \
    -in "$destination/untrusted-server.csr" \
    -CA "$destination/untrusted-ca.crt" \
    -CAkey "$destination/untrusted-ca.key" -CAcreateserial \
    -extfile "$root/tests/server-ext.cnf" \
    -out "$destination/untrusted-server.crt" 2>/dev/null

host_tree="$third_party/bearssl-host"
rm -rf "$host_tree"
cp -R "$bearssl_source" "$host_tree"
rm -rf "$host_tree/build"
make -C "$host_tree" tools CC="$HOST_CC" LD="$HOST_CC" AR="$HOST_AR" \
    >/dev/null
"$host_tree/build/brssl" ta -q "$destination/ca.crt" \
    >"$destination/trust_anchors.c"

printf 'PPNET TEST PKI PASS\n'
