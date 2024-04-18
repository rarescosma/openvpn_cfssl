#!/bin/bash

test -f certs/server.pem || ./init.sh

export SUBNET="${SUBNET:-10.151.0.0}"
export PORT="${PORT:-51196}"

export CA="$(cat certs/ca.pem)"
export CERT="$(openssl x509 -text -in certs/server.pem)"
export KEY="$(cat certs/server-key.pem)"
export DH="$(cat certs/dh.pem)"

cat > ovpn/server.ovpn <<EOF
port ${PORT}
proto udp
dev tun

<ca>
${CA}
</ca>
<cert>
${CERT}
</cert>
<key>
${KEY}
</key>
<dh>
${DH}
</dh>

server ${SUBNET} 255.255.255.0
push "redirect-gateway def1"

push "dhcp-option DNS 8.8.8.8"
push "dhcp-option DNS 8.8.4.4"

duplicate-cn

cipher AES-256-CBC
data-ciphers AES-256-GCM:CHACHA20-POLY1305
tls-version-min 1.2
tls-cipher TLS-DHE-RSA-WITH-AES-256-GCM-SHA384:TLS-DHE-RSA-WITH-AES-256-CBC-SHA256:TLS-DHE-RSA-WITH-AES-128-GCM-SHA256:TLS-DHE-RSA-WITH-AES-128-CBC-SHA256
auth SHA512
auth-nocache

keepalive 20 60
persist-key
persist-tun
verb 3
EOF

