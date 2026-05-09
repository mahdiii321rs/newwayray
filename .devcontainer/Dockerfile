FROM debian:bookworm-slim

COPY install.sh /app/install.sh
COPY start.sh   /app/start.sh

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash git curl wget unzip tzdata openssl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN chmod +x /app/install.sh && /app/install.sh
RUN chmod +x /app/start.sh

# start.sh writes /etc/config.json at runtime (needs CODESPACE_NAME env var)
# then launches xray with that config
CMD ["/app/start.sh"]
