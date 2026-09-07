FROM debian:bookworm-slim

WORKDIR /app

COPY target/release/server /app/server

RUN chmod +x /app/server

CMD ["/app/server"]