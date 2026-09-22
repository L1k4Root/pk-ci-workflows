# Tiny web server used to self-test docker-ci.yml.
FROM busybox:1.37
RUN mkdir -p /www && echo ok > /www/health
EXPOSE 8080
HEALTHCHECK --interval=2s --timeout=2s --start-period=2s --retries=3 \
  CMD wget -q -O /dev/null http://127.0.0.1:8080/health || exit 1
CMD ["httpd", "-f", "-p", "8080", "-h", "/www"]
