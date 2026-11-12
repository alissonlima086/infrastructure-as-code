FROM node:22-alpine AS reveal

WORKDIR /build
COPY package.json package-lock.json ./
RUN npm ci --omit=dev

FROM python:3.13-alpine

RUN addgroup -S slides && adduser -S -G slides slides

WORKDIR /srv/site
COPY --chown=slides:slides slides/ ./
COPY --from=reveal --chown=slides:slides /build/node_modules/reveal.js ./vendor/reveal

ENV CONTAINER_PORT=18080 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

USER slides
EXPOSE 18080

HEALTHCHECK --interval=15s --timeout=3s --start-period=5s --retries=3 \
  CMD python -c "import os, urllib.request; urllib.request.urlopen('http://127.0.0.1:' + os.environ.get('CONTAINER_PORT', '18080'), timeout=2)" || exit 1

CMD ["sh", "-c", "python -m http.server \"${CONTAINER_PORT}\" --bind 0.0.0.0 --directory /srv/site"]
