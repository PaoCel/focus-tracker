#!/usr/bin/env python3
"""App Store Connect per Focus Tracker. Chiave e issuer da ~/.appstoreconnect/config.json
(condiviso con le altre app dell'account): l'app si risolve SEMPRE dal bundle id di
project.yml, mai dall'`app_id` di default del config, che altri progetti spostano.

    asc.py env               esporta ASC_KEY_PATH / ASC_KEY_ID / ASC_ISSUER_ID (per eval)
    asc.py app               id e nome del record app su ASC (esce 2 se manca)
    asc.py builds            ultime build
    asc.py assert-free <n>   fallisce se il numero di build e' gia' su ASC
    asc.py wait-build <n>    attende che la build esca da PROCESSING (max 30 min)
    asc.py internal-group    assicura un gruppo TestFlight interno con tutte le build
                             e l'account holder come tester
"""
import json, re, sys, time, urllib.error, urllib.parse, urllib.request
from pathlib import Path

try:
    import jwt
except ImportError:
    sys.exit("[asc] manca PyJWT: pip3 install pyjwt cryptography")

API = "https://api.appstoreconnect.apple.com"
ROOT = Path(__file__).resolve().parent.parent
CFG = json.load(open(Path.home() / ".appstoreconnect" / "config.json"))
KEY_PATH = Path(CFG["key_path"]).expanduser()
BUNDLE_ID = re.search(r"PRODUCT_BUNDLE_IDENTIFIER:\s*(\S+)", (ROOT / "project.yml").read_text()).group(1)


def token():
    now = int(time.time())
    return jwt.encode({"iss": CFG["issuer_id"], "iat": now, "exp": now + 600, "aud": "appstoreconnect-v1"},
                      KEY_PATH.read_text(), algorithm="ES256", headers={"kid": CFG["key_id"]})


def call(method, path, params=None, body=None):
    url = API + path + (("?" + urllib.parse.urlencode(params)) if params else "")
    req = urllib.request.Request(url, method=method, data=json.dumps(body).encode() if body else None,
                                 headers={"Authorization": "Bearer " + token(), "Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req) as r:
            return json.load(r) if r.status != 204 else {}
    except urllib.error.HTTPError as e:
        sys.exit(f"[asc] HTTP {e.code} {method} {path}: {e.read().decode()[:600]}")


def app():
    d = call("GET", "/v1/apps", {"filter[bundleId]": BUNDLE_ID, "fields[apps]": "name,bundleId"})
    if not d["data"]:
        print(f"[asc] nessun record app su ASC per {BUNDLE_ID}: crealo in App Store Connect "
              f"(I miei app → + → Nuova app, bundle id gia' registrato nel portale).", file=sys.stderr)
        sys.exit(2)
    return d["data"][0]


def builds(app_id, version=None):
    p = {"filter[app]": app_id, "sort": "-uploadedDate", "limit": 10,
         "fields[builds]": "version,processingState,uploadedDate,expired"}
    if version:
        p["filter[version]"] = version
    return call("GET", "/v1/builds", p)["data"]


def main():
    cmd = sys.argv[1] if len(sys.argv) > 1 else "help"
    if cmd == "env":
        print(f'export ASC_KEY_PATH="{KEY_PATH}" ASC_KEY_ID="{CFG["key_id"]}" ASC_ISSUER_ID="{CFG["issuer_id"]}"')
        return
    a = app()
    app_id = a["id"]
    if cmd == "app":
        print(app_id, a["attributes"]["name"], a["attributes"]["bundleId"])
    elif cmd == "builds":
        for b in builds(app_id):
            print(b["attributes"]["version"], b["attributes"]["processingState"], b["attributes"]["uploadedDate"])
    elif cmd == "assert-free":
        if builds(app_id, sys.argv[2]):
            sys.exit(f"[asc] build {sys.argv[2]} gia' su ASC: bumpa CURRENT_PROJECT_VERSION in project.yml")
        print(f"[asc] build {sys.argv[2]} libera")
    elif cmd == "wait-build":
        deadline = time.time() + 1800
        while time.time() < deadline:
            for b in builds(app_id, sys.argv[2]):
                st = b["attributes"]["processingState"]
                if st != "PROCESSING":
                    print(st)
                    sys.exit(0 if st == "VALID" else 1)
            time.sleep(30)
        sys.exit("[asc] build non comparsa entro 30 min")
    elif cmd == "internal-group":
        groups = call("GET", "/v1/betaGroups", {"filter[app]": app_id, "filter[isInternalGroup]": "true",
                                                "fields[betaGroups]": "name,hasAccessToAllBuilds"})["data"]
        if groups:
            g = groups[0]
        else:
            g = call("POST", "/v1/betaGroups", body={"data": {"type": "betaGroups", "attributes": {
                "name": "Interni", "isInternalGroup": True, "hasAccessToAllBuilds": True},
                "relationships": {"app": {"data": {"type": "apps", "id": app_id}}}}})["data"]
            print(f"[asc] gruppo interno creato: {g['id']}")
        holder = [u for u in call("GET", "/v1/users", {"limit": 50, "fields[users]": "username,roles"})["data"]
                  if "ACCOUNT_HOLDER" in u["attributes"]["roles"]][0]["attributes"]["username"]
        testers = call("GET", f"/v1/betaGroups/{g['id']}/betaTesters", {"fields[betaTesters]": "email"})["data"]
        if any(t["attributes"]["email"] == holder for t in testers):
            print(f"[asc] gruppo '{g['attributes']['name']}' ok, {holder} gia' tester")
            return
        existing = call("GET", "/v1/betaTesters", {"filter[email]": holder, "limit": 5})["data"]
        if existing:
            call("POST", f"/v1/betaGroups/{g['id']}/relationships/betaTesters",
                 body={"data": [{"type": "betaTesters", "id": existing[0]["id"]}]})
        else:
            call("POST", "/v1/betaTesters", body={"data": {"type": "betaTesters", "attributes": {"email": holder},
                 "relationships": {"betaGroups": {"data": [{"type": "betaGroups", "id": g["id"]}]}}}})
        print(f"[asc] {holder} aggiunto al gruppo '{g['attributes']['name']}'")
    else:
        print(__doc__)


if __name__ == "__main__":
    main()
