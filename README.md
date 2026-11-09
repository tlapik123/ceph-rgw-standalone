# ceph-rgw-standalone

Ceph RADOS Gateway (S3) without a Ceph cluster: the official
[`quay.io/ceph/ceph`](https://quay.io/repository/ceph/ceph) release image plus a `ceph.conf`
and an entrypoint. Objects are stored as plain files (RGW POSIX backend), metadata in
SQLite/LMDB next to them. For development and testing only. A `-slim` variant carries only
the RGW packages, see [Tags](#tags).

## Quickstart

```sh
podman run -d --name rgw -p 127.0.0.1:7480:7480 -v rgw-data:/data ghcr.io/tlapik123/ceph-rgw-standalone
```

`rgw-data` is a named volume, created on first run and kept across `podman rm rgw`.
To browse objects as files on the host, bind-mount a directory instead. Podman refuses a
bind mount whose source does not exist, so create it first:

```sh
mkdir -p rgw-data
podman run -d --name rgw -p 127.0.0.1:7480:7480 -v ./rgw-data:/data:Z ghcr.io/tlapik123/ceph-rgw-standalone
```

The `./` prefix is what makes the source a host path; a bare name like `rgw-data` is a volume
name. Docker works the same way (drop the `:Z`).

| | |
|---|---|
| Endpoint | `http://127.0.0.1:7480` |
| Access key | `localtest` |
| Secret key | `localtest-secret` |
| Region | any, e.g. `us-east-1` |
| Objects | `<data>/objects/<bucket>/` |
| Metadata | `<data>/db/` |

## Try it with the AWS CLI

```sh
export AWS_ACCESS_KEY_ID=localtest AWS_SECRET_ACCESS_KEY=localtest-secret AWS_DEFAULT_REGION=us-east-1
export AWS_ENDPOINT_URL=http://127.0.0.1:7480
aws s3 mb s3://test-bucket
aws s3 cp README.md s3://test-bucket/
aws s3 ls s3://test-bucket
```

## Configuration

| Variable | Default | |
|---|---|---|
| `RGW_UID` | `testuser` | S3 user created at start if missing |
| `RGW_ACCESS_KEY` | `localtest` | |
| `RGW_SECRET_KEY` | `localtest-secret` | |
| `RGW_TLS` | unset | `1` also serves HTTPS on 7443, see below |

On an existing data directory the entrypoint makes the env pair the user's only key:
the RGW user database authenticates one key per user, so any other key is removed at start.

Arguments after the image name go to `radosgw`, e.g. `--debug-rgw 20`.
Other admin tasks: `podman exec rgw radosgw-admin user list`.

## TLS

```sh
podman run -d --name rgw -p 127.0.0.1:7480:7480 -p 127.0.0.1:7443:7443 -e RGW_TLS=1 -v rgw-data:/data ghcr.io/tlapik123/ceph-rgw-standalone
```

With `RGW_TLS=1` the container also serves HTTPS on 7443 using `<data>/tls/rgw.crt` and
`<data>/tls/rgw.key`. If they are missing, a self-signed pair for `localhost` and `127.0.0.1`
is generated on first start. To use your own pair, place both files there: with a bind mount
before the first start, with a named volume via `podman cp` into the running container followed
by a restart. A `--rgw-frontends` argument of your own replaces this frontend setup, TLS
included; the health check always probes HTTP on 7480. To trust the generated certificate on
the client:

```sh
podman cp rgw:/data/tls/rgw.crt rgw.crt
aws --endpoint-url https://127.0.0.1:7443 --ca-bundle rgw.crt s3 ls
```

## Tags

`:v21.2.0` is the Ceph release the image is built from; `:latest` tracks it. `:v21.2.0-slim`
and `:slim` are Rocky Linux 10 minimal plus only the `ceph-radosgw` RPM and its dependencies
from download.ceph.com: same binaries, config and entrypoint in a fraction of the 1.8 GB.
Images are built for linux/amd64 and linux/arm64 by GitHub Actions from this repository.

## See also

- Upstream [RGW POSIX driver README](https://github.com/ceph/ceph/blob/main/src/rgw/driver/posix/README.md)
- `quay.io/dparkes/zgw-posix`, the driver author's own image built from development RPMs
