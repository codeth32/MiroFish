# Production image for Render. Avoids publicly exposing Vite's dev server
# and runs Flask behind gunicorn on loopback only.
FROM node:22-bookworm-slim AS frontend-build
WORKDIR /app
COPY frontend/package.json frontend/package-lock.json ./frontend/
RUN npm ci --prefix frontend
COPY frontend ./frontend
COPY locales ./locales
# Call the backend through the same HTTPS origin; never through localhost in the browser.
ENV VITE_API_BASE_URL=/
RUN npm run build --prefix frontend

FROM python:3.11-bookworm AS backend-build
COPY --from=ghcr.io/astral-sh/uv:0.9.26 /uv /uvx /bin/
WORKDIR /app
COPY backend/pyproject.toml backend/uv.lock ./backend/
RUN cd backend \
    && uv sync --frozen --no-dev --no-install-project \
    && uv pip install --python .venv/bin/python gunicorn==23.0.0

FROM python:3.11-slim-bookworm
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    VIRTUAL_ENV=/app/backend/.venv \
    PATH="/app/backend/.venv/bin:${PATH}"
RUN apt-get update \
    && apt-get install -y --no-install-recommends nginx openssl libgomp1 ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && rm -f /etc/nginx/sites-enabled/default
WORKDIR /app
COPY --from=backend-build /app/backend/.venv /app/backend/.venv
COPY backend ./backend
COPY --from=frontend-build /app/frontend/dist /usr/share/nginx/html
COPY deploy/nginx.conf /etc/nginx/conf.d/default.conf
COPY deploy/start.sh /usr/local/bin/start-mirofish
RUN chmod +x /usr/local/bin/start-mirofish \
    && mkdir -p /app/backend/uploads \
    && nginx -t

EXPOSE 10000
CMD ["/usr/local/bin/start-mirofish"]
