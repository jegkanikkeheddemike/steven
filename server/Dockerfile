FROM debian:bookworm-slim

WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends libssl3 \
    && rm -rf /var/lib/apt/lists/*


COPY target/release/server /app/server

RUN chmod +x /app/server

CMD ["/app/server"]