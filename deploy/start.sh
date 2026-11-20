#!/usr/bin/env bash
set -euo pipefail

: "${LLM_API_KEY:?Set LLM_API_KEY in Render secret environment variables}"
: "${ZEP_API_KEY:?Set ZEP_API_KEY in Render secret environment variables}"
: "${APP_AUTH_USERNAME:?Set APP_AUTH_USERNAME in Render environment variables}"
: "${APP_AUTH_PASSWORD:?Set APP_AUTH_PASSWORD in Render secret environment variables}"

if [[ ! "${APP_AUTH_USERNAME}" =~ ^[a-zA-Z0-9_.-]+$ ]]; then
  echo "APP_AUTH_USERNAME must contain only letters, digits, _, . or -" >&2
  exit 1
fi
if [[ ${#APP_AUTH_PASSWORD} -lt 12 ]]; then
  echo "APP_AUTH_PASSWORD must contain at least 12 characters" >&2
  exit 1
fi

# Never print API keys or the password in logs. The authentication file
# exists only at runtime inside the container, not in the repository.
umask 077
printf '%s:%s\n' "${APP_AUTH_USERNAME}" "$(printf '%s' "${APP_AUTH_PASSWORD}" | openssl passwd -apr1 -stdin)" \
  > /etc/nginx/.mirofish.htpasswd
unset APP_AUTH_PASSWORD
mkdir -p /app/backend/uploads

# One process keeps in-memory simulation state consistent.
cd /app/backend
/app/backend/.venv/bin/gunicorn --bind 127.0.0.1:5001 \
  --workers 1 --worker-class gthread --threads 8 --timeout 600 \
  'app:create_app()' &
api_pid=$!

nginx -g 'daemon off;' &
web_pid=$!

cleanup() {
  kill "${api_pid}" "${web_pid}" 2>/dev/null || true
  wait "${api_pid}" "${web_pid}" 2>/dev/null || true
}
trap cleanup EXIT
trap 'exit 0' TERM INT

set +e
wait -n "${api_pid}" "${web_pid}"
status=$?
set -e
exit "$status"
