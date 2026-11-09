#!/bin/bash
set -eufo pipefail
mkdir -p /data/objects /data/db /data/run
if radosgw-admin user info --uid="$RGW_UID" >/dev/null 2>&1; then
  # Existing data dir: make the env pair the user's only key. The DBStore user database
  # authenticates just one key per user (the lowest access key id), and removing a user's
  # last key deletes the user, so (re)create the env pair first, then drop the others.
  keys=$(radosgw-admin key create --uid="$RGW_UID" \
    --access-key="$RGW_ACCESS_KEY" --secret-key="$RGW_SECRET_KEY" | jq -r '.keys[].access_key')
  for k in $keys; do
    [[ $k == "$RGW_ACCESS_KEY" ]] || radosgw-admin key rm --uid="$RGW_UID" --access-key="$k" >/dev/null
  done
else
  radosgw-admin user create --uid="$RGW_UID" --display-name="$RGW_UID" \
    --access-key="$RGW_ACCESS_KEY" --secret-key="$RGW_SECRET_KEY" >/dev/null
fi
TLS=()
case ${RGW_TLS:-} in 1|true|yes)
  # HTTPS on 7443 next to HTTP on 7480. Self-signed pair generated once (the image has no
  # openssl binary, python3-cryptography is there); drop your own files in /data/tls instead.
  mkdir -p /data/tls
  if [[ ! -e /data/tls/rgw.crt && ! -e /data/tls/rgw.key ]]; then python3 - /data/tls <<'PY'
import datetime, ipaddress, os, sys
from cryptography import x509
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import rsa
d = sys.argv[1]
os.umask(0o077)
key = rsa.generate_private_key(65537, 2048)
name = x509.Name([x509.NameAttribute(x509.NameOID.COMMON_NAME, "localhost")])
now = datetime.datetime.now(datetime.timezone.utc)
cert = (x509.CertificateBuilder().subject_name(name).issuer_name(name)
        .public_key(key.public_key()).serial_number(x509.random_serial_number())
        .not_valid_before(now).not_valid_after(now + datetime.timedelta(days=3650))
        .add_extension(x509.SubjectAlternativeName([x509.DNSName("localhost"),
            x509.IPAddress(ipaddress.ip_address("127.0.0.1"))]), critical=False)
        .sign(key, hashes.SHA256()))
open(f"{d}/rgw.key.tmp", "wb").write(key.private_bytes(serialization.Encoding.PEM,
    serialization.PrivateFormat.PKCS8, serialization.NoEncryption()))
open(f"{d}/rgw.crt.tmp", "wb").write(cert.public_bytes(serialization.Encoding.PEM))
os.chmod(f"{d}/rgw.crt.tmp", 0o644)
os.replace(f"{d}/rgw.key.tmp", f"{d}/rgw.key"); os.replace(f"{d}/rgw.crt.tmp", f"{d}/rgw.crt")
PY
  elif [[ ! -s /data/tls/rgw.crt || ! -s /data/tls/rgw.key ]]; then
    echo "RGW_TLS: need both /data/tls/rgw.crt and /data/tls/rgw.key, or neither to generate a self-signed pair" >&2
    exit 1
  fi
  TLS=(--rgw-frontends "beast port=7480 ssl_port=7443 ssl_certificate=/data/tls/rgw.crt ssl_private_key=/data/tls/rgw.key")
  ;;
esac
# Root on purpose: under rootless podman, container root maps to the host user, so a
# bind-mounted /data stays owned by whoever ran the container.
exec radosgw -d -n client.rgw.local --setuser root --setgroup root "${TLS[@]}" "$@"
