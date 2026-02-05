#!/usr/bin/env bash
set -euo pipefail

# diagnose-vpn.sh - Diagnose Claude Code connectivity on Bunnings VPN
# Run this while connected to GlobalProtect VPN.
# Paste the output to Claude Code (off VPN) for analysis.

ANTHROPIC_HOST="api.anthropic.com"
PROXY_HOST="vzen01.internal.bunnings.com.au"
PROXY_PORT="80"
CA_FILE="${NODE_EXTRA_CA_CERTS:-$HOME/CAFile.pem}"

# -- Helpers ------------------------------------------------------------------

divider() { echo ""; echo "== $1 =="; }
pass() { echo "  [PASS] $1"; }
fail() { echo "  [FAIL] $1"; }
info() { echo "  [INFO] $1"; }

# -- 1. Environment -----------------------------------------------------------

divider "1. Environment"

info "Date: $(date)"
info "Shell: $SHELL"
info "Node: $(node --version 2>/dev/null || echo 'not found')"

if [[ -n "${HTTP_PROXY:-}" ]]; then
  info "HTTP_PROXY=$HTTP_PROXY"
else
  info "HTTP_PROXY=(unset)"
fi

if [[ -n "${HTTPS_PROXY:-}" ]]; then
  info "HTTPS_PROXY=$HTTPS_PROXY"
else
  info "HTTPS_PROXY=(unset)"
fi

if [[ -n "${NO_PROXY:-}" ]]; then
  info "NO_PROXY=$NO_PROXY"
else
  info "NO_PROXY=(unset)"
fi

if [[ -n "${NODE_EXTRA_CA_CERTS:-}" ]]; then
  info "NODE_EXTRA_CA_CERTS=$NODE_EXTRA_CA_CERTS"
  if [[ -f "$NODE_EXTRA_CA_CERTS" ]]; then
    pass "CA file exists ($(wc -c < "$NODE_EXTRA_CA_CERTS" | tr -d ' ') bytes)"
  else
    fail "CA file does not exist at $NODE_EXTRA_CA_CERTS"
  fi
else
  fail "NODE_EXTRA_CA_CERTS is unset (run proxy-on first?)"
fi

# -- 2. GlobalProtect status ---------------------------------------------------

divider "2. GlobalProtect VPN"

if pgrep -q "GlobalProtect"; then
  pass "GlobalProtect process is running"
else
  fail "GlobalProtect is not running - are you on VPN?"
fi

# Check for Zscaler too (may run alongside GP)
if pgrep -q "ZscalerTunnel\|Zscaler" 2>/dev/null; then
  info "Zscaler tunnel process detected"
fi

# -- 3. DNS resolution --------------------------------------------------------

divider "3. DNS Resolution"

if resolved_ip=$(dig +short "$ANTHROPIC_HOST" 2>/dev/null | head -1); then
  if [[ -n "$resolved_ip" ]]; then
    pass "$ANTHROPIC_HOST resolves to $resolved_ip"
  else
    fail "$ANTHROPIC_HOST did not resolve"
  fi
else
  fail "DNS lookup failed for $ANTHROPIC_HOST"
fi

# -- 4. Direct TLS (no proxy) -------------------------------------------------

divider "4. Direct TLS to $ANTHROPIC_HOST (no proxy)"

echo "  Attempting direct connection..."
direct_tls_output=$(openssl s_client -connect "$ANTHROPIC_HOST:443" -servername "$ANTHROPIC_HOST" </dev/null 2>&1 | head -40)

# Who issued the cert we received?
direct_issuer=$(echo "$direct_tls_output" | grep -m1 "issuer=" | sed 's/.*issuer=//')
if [[ -n "$direct_issuer" ]]; then
  info "Certificate issuer: $direct_issuer"
  if echo "$direct_issuer" | grep -qi "zscaler\|palo alto\|bunnings\|forward trust"; then
    info "SSL inspection DETECTED - Zscaler/corporate CA is intercepting"
  else
    info "No SSL inspection detected - seeing real Anthropic cert"
  fi
else
  fail "Could not extract certificate issuer"
fi

# Did TLS succeed with system trust store?
if echo "$direct_tls_output" | grep -q "Verify return code: 0"; then
  pass "TLS handshake succeeded (system trusts this cert)"
else
  verify_code=$(echo "$direct_tls_output" | grep "Verify return code:" | head -1)
  fail "TLS handshake failed: $verify_code"
fi

# -- 5. Direct TLS with CAFile ------------------------------------------------

divider "5. Direct TLS with CAFile ($CA_FILE)"

if [[ -f "$CA_FILE" ]]; then
  ca_tls_output=$(openssl s_client -connect "$ANTHROPIC_HOST:443" -servername "$ANTHROPIC_HOST" -CAfile "$CA_FILE" </dev/null 2>&1 | head -40)

  if echo "$ca_tls_output" | grep -q "Verify return code: 0"; then
    pass "TLS handshake succeeded with CAFile"
  else
    verify_code=$(echo "$ca_tls_output" | grep "Verify return code:" | head -1)
    fail "TLS handshake failed even with CAFile: $verify_code"
    info "You may need to combine system certs + Zscaler cert into one bundle"
  fi
else
  fail "Skipped - CA file not found"
fi

# -- 6. Proxy connectivity ----------------------------------------------------

divider "6. Proxy Connectivity"

# Can we reach the proxy?
if nc -z -w5 "$PROXY_HOST" "$PROXY_PORT" 2>/dev/null; then
  pass "Proxy $PROXY_HOST:$PROXY_PORT is reachable"
else
  fail "Cannot reach proxy $PROXY_HOST:$PROXY_PORT"
  info "If off VPN, this is expected"
fi

# -- 7. HTTPS via proxy -------------------------------------------------------

divider "7. HTTPS to $ANTHROPIC_HOST via proxy"

proxy_curl_output=$(curl -sS -o /dev/null -w "%{http_code}" \
  --proxy "http://$PROXY_HOST:$PROXY_PORT" \
  --cacert "$CA_FILE" \
  --max-time 10 \
  "https://$ANTHROPIC_HOST/" 2>&1) || true

if [[ "$proxy_curl_output" =~ ^[0-9]+$ ]]; then
  if [[ "$proxy_curl_output" -ge 200 && "$proxy_curl_output" -lt 500 ]]; then
    pass "Got HTTP $proxy_curl_output through proxy (connection works)"
  elif [[ "$proxy_curl_output" == "403" ]]; then
    fail "HTTP 403 - proxy is blocking api.anthropic.com"
    info "Anthropic domain may be on a corporate blocklist"
  else
    info "HTTP $proxy_curl_output through proxy"
  fi
else
  fail "Proxy request failed: $proxy_curl_output"
fi

# -- 8. curl direct with CAFile (no proxy) ------------------------------------

divider "8. curl direct to $ANTHROPIC_HOST (no proxy, with CAFile)"

direct_curl_output=$(curl -sS -o /dev/null -w "%{http_code}" \
  --noproxy "*" \
  --cacert "$CA_FILE" \
  --max-time 10 \
  "https://$ANTHROPIC_HOST/" 2>&1) || true

if [[ "$direct_curl_output" =~ ^[0-9]+$ ]]; then
  if [[ "$direct_curl_output" -ge 200 && "$direct_curl_output" -lt 500 ]]; then
    pass "Got HTTP $direct_curl_output direct (no proxy needed)"
    info "You might not need the proxy for Anthropic at all"
  else
    info "HTTP $direct_curl_output direct"
  fi
else
  fail "Direct request failed: $direct_curl_output"
  info "May need proxy, or Zscaler is blocking without it"
fi

# -- 9. Node.js TLS test ------------------------------------------------------

divider "9. Node.js TLS Test"

if command -v node &>/dev/null; then
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

  if echo "$node_result" | grep -q "HTTP"; then
    pass "Node.js connected: $node_result"
  else
    fail "Node.js failed: $node_result"
  fi

  # Same test but with proxy
  if [[ -n "${HTTPS_PROXY:-}" ]]; then
    node_proxy_result=$(NODE_EXTRA_CA_CERTS="$CA_FILE" HTTPS_PROXY="http://$PROXY_HOST:$PROXY_PORT" node -e "
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
    info "Node.js via proxy: $node_proxy_result"
  fi
else
  fail "Node.js not found"
fi

# -- 10. Summary ---------------------------------------------------------------

divider "10. Summary"

echo ""
echo "  Copy everything above and paste it to Claude Code (off VPN)."
echo "  It will tell you exactly what to fix."
echo ""
