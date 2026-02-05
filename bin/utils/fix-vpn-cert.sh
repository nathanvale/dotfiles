#!/usr/bin/env bash
set -euo pipefail

# fix-vpn-cert.sh - Extract the correct Zscaler root CA for Bunnings VPN
#
# Bunnings' Zscaler instance presents a tenant-specific certificate chain:
#   api.anthropic.com
#     -> CN=<tenant-id> Forward Trust CA ECDSA
#       -> CN=<tenant-id> Root CA  (self-signed)
#
# Node.js needs the root CA in NODE_EXTRA_CA_CERTS to trust TLS connections.
# This script extracts it from the live chain and writes it to ~/CAFile.pem.
#
# Usage: Run while connected to GlobalProtect VPN.
#   ./fix-vpn-cert.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../colour_log.sh"

ANTHROPIC_HOST="api.anthropic.com"
CA_FILE="$HOME/CAFile.pem"
CA_BACKUP="$HOME/CAFile.pem.bak"

# -- 1. Pre-flight checks ----------------------------------------------------

log "$INFO" "Pre-flight checks..."

if ! pgrep -q "GlobalProtect"; then
  log "$ERROR" "GlobalProtect is not running. Connect to VPN first."
  exit 1
fi
log "$INFO" "GlobalProtect is running"

if ! dig +short "$ANTHROPIC_HOST" >/dev/null 2>&1; then
  log "$ERROR" "Cannot resolve $ANTHROPIC_HOST - DNS issue?"
  exit 1
fi
log "$INFO" "$ANTHROPIC_HOST resolves OK"

# -- 2. Extract root CA from live TLS chain -----------------------------------

log "$INFO" "Connecting to $ANTHROPIC_HOST to extract certificate chain..."

# Get the full certificate chain. openssl s_client -showcerts outputs all certs
# in the chain. The last one is the root CA (self-signed).
chain_output=$(openssl s_client \
  -connect "$ANTHROPIC_HOST:443" \
  -servername "$ANTHROPIC_HOST" \
  -showcerts </dev/null 2>/dev/null) || true

if [[ -z "$chain_output" ]]; then
  log "$ERROR" "Could not connect to $ANTHROPIC_HOST:443"
  exit 1
fi

# Extract all PEM certificates from the chain
certs=()
current_cert=""
in_cert=false

while IFS= read -r line; do
  if [[ "$line" == "-----BEGIN CERTIFICATE-----" ]]; then
    in_cert=true
    current_cert="$line"
  elif [[ "$line" == "-----END CERTIFICATE-----" ]]; then
    current_cert="$current_cert"$'\n'"$line"
    certs+=("$current_cert")
    current_cert=""
    in_cert=false
  elif $in_cert; then
    current_cert="$current_cert"$'\n'"$line"
  fi
done <<< "$chain_output"

cert_count=${#certs[@]}

if [[ $cert_count -eq 0 ]]; then
  log "$ERROR" "No certificates found in the TLS chain"
  exit 1
fi

log "$INFO" "Found $cert_count certificate(s) in chain"

# The last cert in the chain is the root CA
root_cert="${certs[$((cert_count - 1))]}"

# -- 3. Verify extracted cert -------------------------------------------------

log "$INFO" "Verifying extracted root CA..."

# Parse cert details
cert_subject=$(echo "$root_cert" | openssl x509 -noout -subject 2>/dev/null | sed 's/.*CN *= *//')
cert_issuer=$(echo "$root_cert" | openssl x509 -noout -issuer 2>/dev/null | sed 's/.*CN *= *//')
cert_dates=$(echo "$root_cert" | openssl x509 -noout -dates 2>/dev/null)
cert_start=$(echo "$cert_dates" | grep "notBefore" | sed 's/notBefore=//')
cert_end=$(echo "$cert_dates" | grep "notAfter" | sed 's/notAfter=//')

echo ""
echo "  Subject: $cert_subject"
echo "  Issuer:  $cert_issuer"
echo "  Valid:   $cert_start"
echo "  Expires: $cert_end"
echo ""

# Verify it's self-signed (subject == issuer for root CAs)
if [[ "$cert_subject" != "$cert_issuer" ]]; then
  log "$WARNING" "Certificate is NOT self-signed (subject != issuer)"
  log "$WARNING" "This may not be the root CA. Proceeding anyway - the chain's last cert is the best candidate."
fi

# -- 4. Backup old CAFile.pem -------------------------------------------------

if [[ -f "$CA_FILE" ]]; then
  # Only backup if content is different
  existing_hash=$(shasum -a 256 "$CA_FILE" | cut -d' ' -f1)
  new_hash=$(echo "$root_cert" | shasum -a 256 | cut -d' ' -f1)

  if [[ "$existing_hash" == "$new_hash" ]]; then
    log "$INFO" "CAFile.pem already contains the correct cert - no changes needed"
  else
    cp "$CA_FILE" "$CA_BACKUP"
    log "$INFO" "Backed up existing CAFile.pem to CAFile.pem.bak"
  fi
else
  log "$INFO" "No existing CAFile.pem found - creating new one"
fi

# -- 5. Write new CAFile.pem --------------------------------------------------

echo "$root_cert" > "$CA_FILE"
log "$INFO" "Wrote root CA to $CA_FILE ($(wc -c < "$CA_FILE" | tr -d ' ') bytes)"

# -- 6. Node.js smoke test ----------------------------------------------------

log "$INFO" "Running Node.js smoke test..."

node_result=$(NODE_EXTRA_CA_CERTS="$CA_FILE" node -e "
  const https = require('https');
  const req = https.get('https://$ANTHROPIC_HOST/', (res) => {
    console.log('HTTP ' + res.statusCode);
    req.destroy();
  });
  req.on('error', (e) => {
    console.log('ERROR: ' + e.message);
  });
  req.setTimeout(10000, () => {
    console.log('ERROR: timeout');
    req.destroy();
  });
" 2>&1)

# -- 7. Report result ---------------------------------------------------------

echo ""
if echo "$node_result" | grep -q "^HTTP"; then
  log "$INFO" "PASS - Node.js connected: $node_result"
  echo ""
  echo "  Claude Code should now work on VPN."
  echo "  Make sure proxy-on is active (sets NODE_EXTRA_CA_CERTS=~/CAFile.pem)."
  echo ""
else
  log "$ERROR" "FAIL - Node.js could not connect: $node_result"
  echo ""
  echo "  Next steps:"
  echo "  1. Check proxy-on is active (sets HTTP_PROXY and NODE_EXTRA_CA_CERTS)"
  echo "  2. Run diagnose-vpn.sh for detailed diagnostics"
  echo "  3. If the cert rotated, re-run this script"
  echo ""
  exit 1
fi
