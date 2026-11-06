# ceph-rgw-standalone

Ceph RADOS Gateway (S3) without a Ceph cluster: the official
[`quay.io/ceph/ceph`](https://quay.io/repository/ceph/ceph) release image plus a `ceph.conf`
and an entrypoint. Objects are stored as plain files (RGW POSIX backend), metadata in
SQLite/LMDB next to them. For development and testing only.

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

Docker works the same way (drop the `:Z`).

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

On an existing data directory the entrypoint makes the env pair the user's only key:
the RGW user database authenticates one key per user, so any other key is removed at start.

Arguments after the image name go to `radosgw`, e.g. `--debug-rgw 20`.
Other admin tasks: `podman exec rgw radosgw-admin user list`.

## Tags

`:v21.2.0` is the Ceph release the image is built from; `:latest` tracks it. Images are
built for linux/amd64 and linux/arm64 by GitHub Actions from this repository.

## See also

- Upstream [RGW POSIX driver README](https://github.com/ceph/ceph/blob/main/src/rgw/driver/posix/README.md)
- `quay.io/dparkes/zgw-posix`, the driver author's own image built from development RPMs
