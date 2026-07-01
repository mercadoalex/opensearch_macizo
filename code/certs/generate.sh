#!/bin/bash
# =============================================================================
# generate.sh — Genera certificados TLS auto-firmados para OpenSearch
# =============================================================================
#
# ⚠️  SOLO PARA DESARROLLO Y LABORATORIO — NO USAR EN PRODUCCIÓN ⚠️
#
# Este script genera certificados auto-firmados para el perfil "ninja" del
# laboratorio Docker Compose. Los certificados generados son:
#
#   - root-ca.pem / root-ca-key.pem   → Autoridad certificadora raíz
#   - node.pem / node-key.pem         → Certificado del nodo OpenSearch
#   - admin.pem / admin-key.pem       → Certificado del cliente admin
#
# Estos certificados permiten cifrado TLS en tránsito entre nodos y entre
# clientes y el clúster, como requiere el Security Plugin de OpenSearch.
#
# Uso:
#   cd code/certs/
#   chmod +x generate.sh
#   ./generate.sh
#
# Requisitos:
#   - openssl (cualquier versión moderna, ≥ 1.1.1)
#
# =============================================================================

set -euo pipefail

CERTS_DIR="$(cd "$(dirname "$0")" && pwd)"
DAYS_VALID=730
KEY_SIZE=2048

echo "============================================="
echo "  Generando certificados TLS para OpenSearch"
echo "  ⚠️  SOLO PARA DESARROLLO / LABORATORIO"
echo "============================================="
echo ""

cd "$CERTS_DIR"

# -----------------------------------------------------------------------------
# 1. Root CA — Autoridad certificadora raíz
# -----------------------------------------------------------------------------
echo "[1/3] Generando Root CA..."

openssl genrsa -out root-ca-key.pem "$KEY_SIZE"

openssl req -new -x509 \
  -sha256 \
  -key root-ca-key.pem \
  -subj "/C=MX/ST=Lab/L=Dev/O=OpenSearch-Macizo/OU=CA/CN=Root CA (DEV ONLY)" \
  -days "$DAYS_VALID" \
  -out root-ca.pem

echo "  ✓ root-ca.pem y root-ca-key.pem generados"

# -----------------------------------------------------------------------------
# 2. Node Certificate — Para nodos OpenSearch
# -----------------------------------------------------------------------------
echo "[2/3] Generando certificado de nodo..."

openssl genrsa -out node-key.pem "$KEY_SIZE"

openssl req -new \
  -sha256 \
  -key node-key.pem \
  -subj "/C=MX/ST=Lab/L=Dev/O=OpenSearch-Macizo/OU=Node/CN=opensearch-node" \
  -out node.csr

# Extensiones SAN para que el certificado sea válido para los hostnames del lab
cat > node-ext.cnf <<EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = opensearch-node1
DNS.2 = opensearch-node2
DNS.3 = opensearch-node3
DNS.4 = localhost
IP.1 = 127.0.0.1
EOF

openssl x509 -req \
  -sha256 \
  -in node.csr \
  -CA root-ca.pem \
  -CAkey root-ca-key.pem \
  -CAcreateserial \
  -days "$DAYS_VALID" \
  -extfile node-ext.cnf \
  -out node.pem

echo "  ✓ node.pem y node-key.pem generados"

# -----------------------------------------------------------------------------
# 3. Admin Certificate — Para operaciones administrativas
# -----------------------------------------------------------------------------
echo "[3/3] Generando certificado admin..."

openssl genrsa -out admin-key.pem "$KEY_SIZE"

openssl req -new \
  -sha256 \
  -key admin-key.pem \
  -subj "/C=MX/ST=Lab/L=Dev/O=OpenSearch-Macizo/OU=Admin/CN=admin" \
  -out admin.csr

cat > admin-ext.cnf <<EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
EOF

openssl x509 -req \
  -sha256 \
  -in admin.csr \
  -CA root-ca.pem \
  -CAkey root-ca-key.pem \
  -CAcreateserial \
  -days "$DAYS_VALID" \
  -extfile admin-ext.cnf \
  -out admin.pem

echo "  ✓ admin.pem y admin-key.pem generados"

# -----------------------------------------------------------------------------
# Limpieza de archivos temporales
# -----------------------------------------------------------------------------
rm -f node.csr node-ext.cnf admin.csr admin-ext.cnf root-ca.srl

echo ""
echo "============================================="
echo "  ✅ Certificados generados exitosamente"
echo ""
echo "  Archivos:"
echo "    root-ca.pem      — CA raíz (público)"
echo "    root-ca-key.pem  — Llave privada CA"
echo "    node.pem         — Cert nodo (público)"
echo "    node-key.pem     — Llave privada nodo"
echo "    admin.pem        — Cert admin (público)"
echo "    admin-key.pem    — Llave privada admin"
echo ""
echo "  ⚠️  Estos certificados son SOLO para el"
echo "     laboratorio. NO usar en producción."
echo "============================================="
