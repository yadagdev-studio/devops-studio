FROM alpine:3.20
RUN apk add --no-cache curl bash openssl coreutils
WORKDIR /app

COPY monitor.sh /app/monitor.sh
COPY lib/ /app/lib/
COPY checks/ /app/checks/

RUN chmod +x /app/monitor.sh /app/checks/*.sh
ENTRYPOINT ["/app/monitor.sh"]