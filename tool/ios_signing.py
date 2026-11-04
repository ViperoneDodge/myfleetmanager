import base64
import json
import os
import sys
import time
import urllib.error
import urllib.request

import jwt
from cryptography import x509
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.hazmat.primitives.serialization import pkcs12
from cryptography.x509.oid import NameOID

API = "https://api.appstoreconnect.apple.com/v1"
BUNDLE = "it.myfleet.myfleetmanager"
TEMP = os.environ["RUNNER_TEMP"]
STATE = os.path.join(TEMP, "signing.json")


def token():
    key = open(os.path.join(TEMP, "keys", "AuthKey.p8")).read()
    now = int(time.time())
    return jwt.encode(
        {"iss": os.environ["ASC_ISSUER_ID"].strip(), "iat": now, "exp": now + 900, "aud": "appstoreconnect-v1"},
        key,
        algorithm="ES256",
        headers={"kid": os.environ["ASC_KEY_ID"].strip(), "typ": "JWT"},
    )


def call(method, path, body=None):
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(API + path, data=data, method=method)
    req.add_header("Authorization", "Bearer " + token())
    req.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(req) as r:
            raw = r.read()
            return json.loads(raw) if raw else {}
    except urllib.error.HTTPError as e:
        print("Errore Apple", method, path, e.code, e.read().decode()[:600])
        raise SystemExit(1)


def env(name, value):
    with open(os.environ["GITHUB_ENV"], "a") as f:
        f.write(f"{name}={value}\n")


def create():
    bundles = call("GET", f"/bundleIds?filter[identifier]={BUNDLE}&limit=5")["data"]
    bundle = next((b for b in bundles if b["attributes"]["identifier"] == BUNDLE), None)
    if bundle is None:
        print("Bundle ID non trovato:", BUNDLE)
        raise SystemExit(1)

    key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
    csr = (
        x509.CertificateSigningRequestBuilder()
        .subject_name(x509.Name([x509.NameAttribute(NameOID.COMMON_NAME, "MyFleetManager CI")]))
        .sign(key, hashes.SHA256())
    )
    csr_pem = csr.public_bytes(serialization.Encoding.PEM).decode()
    cert = call("POST", "/certificates", {
        "data": {"type": "certificates", "attributes": {"certificateType": "DISTRIBUTION", "csrContent": csr_pem}}
    })["data"]
    state = {"certificate": cert["id"]}
    json.dump(state, open(STATE, "w"))
    der = base64.b64decode(cert["attributes"]["certificateContent"])
    certificate = x509.load_der_x509_certificate(der)
    password = base64.b16encode(os.urandom(12)).decode()
    legacy = (
        serialization.PrivateFormat.PKCS12.encryption_builder()
        .kdf_rounds(50000)
        .key_cert_algorithm(pkcs12.PBES.PBESv1SHA1And3KeyTripleDESCBC)
        .hmac_hash(hashes.SHA1())
        .build(password.encode())
    )
    p12 = pkcs12.serialize_key_and_certificates(b"MyFleetManager CI", key, certificate, None, legacy)
    open(os.path.join(TEMP, "dist.p12"), "wb").write(p12)
    open(os.path.join(TEMP, "dist.pass"), "w").write(password)

    name = f"MyFleetManager CI {int(time.time())}"
    profile = call("POST", "/profiles", {
        "data": {
            "type": "profiles",
            "attributes": {"name": name, "profileType": "IOS_APP_STORE"},
            "relationships": {
                "bundleId": {"data": {"type": "bundleIds", "id": bundle["id"]}},
                "certificates": {"data": [{"type": "certificates", "id": cert["id"]}]},
            },
        }
    })["data"]
    state["profile"] = profile["id"]
    json.dump(state, open(STATE, "w"))
    content = base64.b64decode(profile["attributes"]["profileContent"])
    folder = os.path.expanduser("~/Library/MobileDevice/Provisioning Profiles")
    os.makedirs(folder, exist_ok=True)
    open(os.path.join(folder, profile["attributes"]["uuid"] + ".mobileprovision"), "wb").write(content)

    print(f"::add-mask::{password}")
    env("IOS_PROFILE_NAME", name)
    env("IOS_P12_PASSWORD", password)
    print("Certificato di distribuzione e profilo App Store creati:", name)


def cleanup():
    if not os.path.exists(STATE):
        return
    state = json.load(open(STATE))
    if "profile" in state:
        call("DELETE", f"/profiles/{state['profile']}")
    if "certificate" in state:
        call("DELETE", f"/certificates/{state['certificate']}")
    os.remove(STATE)
    print("Certificato e profilo temporanei eliminati")


if __name__ == "__main__":
    {"create": create, "cleanup": cleanup}[sys.argv[1]]()
