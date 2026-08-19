#!/bin/sh
# Run the Node API and nginx in one container.
#
# nginx is PID 1's foreground child because Railway routes to it; the API is a
# background job kept alive by a restart loop, so a crashed backend recovers on
# its own instead of leaving a site whose /api is a black hole.
set -e

: "${PORT:=8080}"
: "${API_PORT:=3000}"
: "${DATA_DIR:=/data}"
export PORT API_PORT DATA_DIR

# Only these two expand — nginx's own $uri/$host/$scheme must survive verbatim.
envsubst '${PORT} ${API_PORT}' \
  < /etc/nginx/opengym.conf.template \
  > /etc/nginx/http.d/default.conf

mkdir -p "$DATA_DIR"

echo "[entrypoint] nginx :${PORT}  →  api 127.0.0.1:${API_PORT}  (DATA_DIR=${DATA_DIR})"
echo "[entrypoint] RP_ID=${RP_ID:-<unset>}  ORIGIN=${ORIGIN:-<unset>}"

(
  while true; do
    # The API reads PORT; give it the internal one, not the public nginx port.
    PORT="$API_PORT" node /app/server.js || echo "[entrypoint] api exited — restarting in 2s" >&2
    sleep 2
  done
) &

exec nginx -g 'daemon off;'
