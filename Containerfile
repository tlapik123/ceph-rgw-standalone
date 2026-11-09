ARG CEPH_IMAGE=quay.io/ceph/ceph:v21.2.0
FROM ${CEPH_IMAGE}
COPY ceph.conf /etc/ceph/ceph.conf
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
ENV RGW_UID=testuser RGW_ACCESS_KEY=localtest RGW_SECRET_KEY=localtest-secret
LABEL org.opencontainers.image.source=https://github.com/tlapik123/ceph-rgw-standalone \
      org.opencontainers.image.title=ceph-rgw-standalone \
      org.opencontainers.image.licenses=Apache-2.0
VOLUME /data
EXPOSE 7480 7443
HEALTHCHECK --interval=10s --timeout=3s --start-period=30s CMD curl -sf http://127.0.0.1:7480/ || exit 1
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
