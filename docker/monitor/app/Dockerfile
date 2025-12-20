FROM alpine:3.20
RUN apk add --no-cache curl bash
WORKDIR /app
COPY healthcheck.sh /app/healthcheck.sh
RUN chmod +x /app/healthcheck.sh
ENTRYPOINT ["/app/healthcheck.sh"]