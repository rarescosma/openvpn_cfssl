#!/bin/bash
# Make a new client
if [[ -z $1 ]]; then
    echo "Usage: $0 CLIENTNAME"
    echo "Generates a new client certificate"
    exit 1
fi

test -f certs/server.pem || ./server.sh

export REMOTE="${REMOTE:-acme.com}"
export PORT="${PORT:-51196}"

echo "# Making client certificate"
cfssl gencert -ca certs/ca.pem -ca-key certs/ca-key.pem \
    -config="config/config_ca.json" -profile="client" \
    -hostname="$1" \
    <(sed "1a\\
     \\    \"cn\": \"$1\",
     " config/csr.json) | \
    cfssljson -bare "certs/$1"

export CA="$(cat certs/ca.pem)"
export CERT="$(openssl x509 -text -in certs/${1}.pem)"
export KEY="$(cat certs/${1}-key.pem)"

cat > ovpn/$1.ovpn <<EOF
client
dev tun
proto udp

remote ${REMOTE} ${PORT}

<ca>
${CA}
</ca>
<cert>
${CERT}
</cert>
<key>
${KEY}
</key>

cipher AES-256-CBC
auth SHA512
auth-nocache
data-ciphers AES-256-GCM:CHACHA20-POLY1305
tls-version-min 1.2
tls-cipher TLS-DHE-RSA-WITH-AES-256-GCM-SHA384:TLS-DHE-RSA-WITH-AES-256-CBC-SHA256:TLS-DHE-RSA-WITH-AES-128-GCM-SHA256:TLS-DHE-RSA-WITH-AES-128-CBC-SHA256

resolv-retry infinite
nobind
persist-key
persist-tun
mute-replay-warnings
verb 3
EOF

