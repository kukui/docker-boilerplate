#!/bin/bash
# make a self signed certificate for $DOMAIN
cat > openssl.cnf <<-EOF
  [req]
  distinguished_name = req_distinguished_name
  x509_extensions = v3_req
  prompt = no
  [req_distinguished_name]
  C=US
  ST=California
  L=San Luis Obispo
  O=kukui enterprises
  OU=Development Domain
  emailAddress=kai@kukui.io
  CN=$DOMAIN
  [v3_req]
  authorityKeyIdentifier=keyid,issuer
  keyUsage=digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
  extendedKeyUsage=serverAuth
  subjectAltName=@alt_names
  [alt_names]
  DNS.1=$DOMAIN
EOF

openssl req \
  -new \
  -newkey rsa:2048 \
  -sha1 \
  -days 365 \
  -nodes \
  -x509 \
  -keyout www/certs/$DOMAIN.key \
  -out www/certs/$DOMAIN.crt \
  -config openssl.cnf

rm openssl.cnf
