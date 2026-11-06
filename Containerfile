ARG CEPH_IMAGE=quay.io/ceph/ceph:v21.2.0
FROM ${CEPH_IMAGE}
COPY ceph.conf /etc/ceph/ceph.conf
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
ENV RGW_UID=testuser RGW_ACCESS_KEY=localtest RGW_SECRET_KEY=localtest-secret
LABEL org.opencontainers.image.source=https://github.com/tlapik123/ceph-rgw-standalone \
      org.opencontainers.image.title=ceph-rgw-standalone \
      org.opencontainers.image.licenses=Apache-2.0
VOLUME /data
EXPOSE 7480
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
