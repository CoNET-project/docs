#!/usr/bin/env bash
# Deploy CoNET HonKit site → gitbook.conet.network on 38.102.126.50
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BOOK_DIR="${ROOT}/gitbook"
REMOTE_HOST="${REMOTE_HOST:-38.102.126.50}"
REMOTE_USER="${REMOTE_USER:-peter}"
REMOTE_WWW="${REMOTE_WWW:-/var/www/gitbook.conet.network}"
DOMAIN="${DOMAIN:-gitbook.conet.network}"
NGINX_AVAIL="/etc/nginx/sites-available/${DOMAIN}.conf"
NGINX_ENABLED="/etc/nginx/sites-enabled/${DOMAIN}.conf"
NGINX_TEMPLATE="${ROOT}/scripts/gitbook.conet.network.conf"
REMOTE_NGINX_TEMPLATE="/tmp/${DOMAIN}.deploy.conf"
RENDERED_NGINX="$(mktemp)"
VERIFY_DIR=""
cleanup() {
	rm -f "${RENDERED_NGINX}"
	if [[ -n "${VERIFY_DIR}" ]]; then
		rm -rf "${VERIFY_DIR}"
	fi
}
trap cleanup EXIT

sed \
	-e "s|__DOMAIN__|${DOMAIN}|g" \
	-e "s|__REMOTE_WWW__|${REMOTE_WWW}|g" \
	"${NGINX_TEMPLATE}" > "${RENDERED_NGINX}"

if [[ "${1:-}" == "--sync" ]]; then
	echo "ERROR: doceng sync is deprecated. Author content under gitbook/ (see archive/doceng-mirror/)." >&2
	exit 1
fi

echo "==> Install + build HonKit"
cd "${BOOK_DIR}"
npm ci
rm -rf _book
npm run build
test -f _book/index.html
# HonKit may omit non-markdown binaries; publish genesis artifacts explicitly.
mkdir -p _book/l1/network
cp -a l1/network/genesis.json l1/network/genesis.ssz l1/network/config.yml l1/network/SHA256SUMS _book/l1/network/
test -s _book/l1/network/genesis.ssz
# Theme default favicon is not the CoNET mark; copy after HonKit (npm run build already does this).
node copyConetFavicon.cjs
test -s _book/favicon.ico
test -s _book/gitbook/images/favicon.ico
rm -f _book/package.json _book/package-lock.json

echo "==> Ensure remote web root"
ssh -o BatchMode=yes "${REMOTE_USER}@${REMOTE_HOST}" \
	"mkdir -p '${REMOTE_WWW}' /var/www/certbot/.well-known/acme-challenge"

echo "==> Rsync static site"
rsync -avz --delete \
	-e 'ssh -o BatchMode=yes' \
	"${BOOK_DIR}/_book/" \
	"${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_WWW}/"

echo "==> Install nginx vhost"
scp -o BatchMode=yes "${RENDERED_NGINX}" \
	"${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_NGINX_TEMPLATE}"

echo "==> TLS + reload nginx"
ssh -o BatchMode=yes "${REMOTE_USER}@${REMOTE_HOST}" bash -s -- \
	"${DOMAIN}" "${NGINX_AVAIL}" "${NGINX_ENABLED}" "${REMOTE_WWW}" "${REMOTE_NGINX_TEMPLATE}" <<'REMOTE'
set -euo pipefail
DOMAIN="$1"
NGINX_AVAIL="$2"
NGINX_ENABLED="$3"
REMOTE_WWW="$4"
REMOTE_NGINX_TEMPLATE="$5"
trap 'rm -f "${REMOTE_NGINX_TEMPLATE}"' EXIT

sudo ln -sfn "${NGINX_AVAIL}" "${NGINX_ENABLED}"

if ! sudo test -f "/etc/letsencrypt/live/${DOMAIN}/fullchain.pem"; then
  # HTTP-only bootstrap for first cert
  sudo tee "${NGINX_AVAIL}" >/dev/null <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name ${DOMAIN};
    location ^~ /.well-known/acme-challenge/ {
        alias /var/www/certbot/.well-known/acme-challenge/;
        default_type "text/plain";
    }
    location = /l0/silentpass-vpn.html {
        return 301 /applications/silentpass-vpn.html;
    }
    location = /l0/silentpass-vpn {
        return 301 /applications/silentpass-vpn.html;
    }
    location = /l0/silentpass-vpn.md {
        return 301 /applications/silentpass-vpn.html;
    }
    location = /applications.html {
        return 301 /applications/;
    }
    location / {
        root ${REMOTE_WWW};
        index index.html;
        try_files \$uri \$uri/ \$uri.html \$uri/index.html =404;
    }
}
EOF
  sudo nginx -t
  sudo systemctl restart nginx
  sudo certbot certonly --webroot -w /var/www/certbot \
    -d "${DOMAIN}" \
    --non-interactive --agree-tos \
    --register-unsafely-without-email \
    --keep-until-expiring
fi

# The checked-in template is the single source for the final TLS vhost.
sudo install -m 0644 "${REMOTE_NGINX_TEMPLATE}" "${NGINX_AVAIL}"

sudo nginx -t
# Full restart: reload alone has left stale workers on this host before
sudo systemctl restart nginx
echo "nginx OK for ${DOMAIN}"
REMOTE

echo "==> Smoke"
sleep 1
SMOKE_PATHS=(
	"/"
	"/overview.html"
	"/open-source.html"
	"/developers/"
	"/developers/l0.html"
	"/developers/l1-node.html"
	"/developers/conet-l0d.html"
	"/developers/l1-mining.html"
	"/developers/l1-erc20-bridge.html"
	"/l1/network/genesis.json"
	"/l1/network/genesis.ssz"
	"/l1/network/config.yml"
	"/l1/network/SHA256SUMS"
	"/developers/l2.html"
	"/l0/"
	"/l0/layer-minus.html"
	"/l0/web3-application-protocol.html"
	"/l0/permissionless-cloud.html"
	"/l0/using-l0.html"
	"/l0/hop-sigs.html"
	"/l0/peel-hop-listen.html"
	"/l0/si-developer-guide.html"
	"/l0/chat-developer-guide.html"
	"/l0/mailbox-routing.html"
	"/l0/duplex-forward.html"
	"/l1/rpc-explorer.html"
	"/l1/cross-chain-treasury.html"
	"/l1/"
	"/l2/"
	"/l2/design-thesis.html"
	"/l2/archive-plane.html"
	"/l2/routing-registry.html"
	"/l2/cross-chain-assets.html"
	"/l2/explorer.html"
	"/favicon.ico"
	"/gitbook/images/favicon.ico"
	"/applications/"
	"/applications/beamio.html"
	"/applications/privacy-first-ai.html"
	"/applications/privacy-first-ai-whitepaper.html"
	"/applications/privacy-first-ai-structure.png"
	"/applications/silentpass-vpn.html"
	"/applications/depin-chat.html"
	"/applications/web3-url.html"
	"/applications/miner-orderbook-dex.html"
	"/use-cases/decentralized-sns.html"
	"/resources.html"
)
for path in "${SMOKE_PATHS[@]}"; do
	status="$(curl --fail --silent --show-error --output /dev/null --write-out '%{http_code}' "https://${DOMAIN}${path}")"
	echo "${status} https://${DOMAIN}${path}"
done

REDIRECTS=(
	"/l0/silentpass-vpn.html|/applications/silentpass-vpn.html"
	"/l0/silentpass-vpn|/applications/silentpass-vpn.html"
	"/l0/silentpass-vpn.md|/applications/silentpass-vpn.html"
	"/applications.html|/applications/"
)
for mapping in "${REDIRECTS[@]}"; do
	IFS='|' read -r source_path target_path <<< "${mapping}"
	read -r status redirect_url < <(
		curl --silent --show-error --output /dev/null --max-redirs 0 \
			--write-out '%{http_code} %{redirect_url}\n' \
			"https://${DOMAIN}${source_path}"
	)
	expected_url="https://${DOMAIN}${target_path}"
	if [[ "${status}" != "301" || "${redirect_url}" != "${expected_url}" ]]; then
		echo "ERROR: redirect ${source_path} returned ${status} ${redirect_url}; expected 301 ${expected_url}" >&2
		exit 1
	fi
	echo "${status} https://${DOMAIN}${source_path} -> ${redirect_url}"
done

echo "==> Verify published genesis checksums"
VERIFY_DIR="$(mktemp -d)"
(
	cd "${VERIFY_DIR}"
	curl -fsSL -O "https://${DOMAIN}/l1/network/genesis.json"
	curl -fsSL -O "https://${DOMAIN}/l1/network/genesis.ssz"
	curl -fsSL -O "https://${DOMAIN}/l1/network/config.yml"
	curl -fsSL -O "https://${DOMAIN}/l1/network/SHA256SUMS"
	if command -v sha256sum >/dev/null 2>&1; then
		sha256sum -c SHA256SUMS
	else
		shasum -a 256 -c SHA256SUMS
	fi
)
echo "Deployed: https://${DOMAIN}/"
