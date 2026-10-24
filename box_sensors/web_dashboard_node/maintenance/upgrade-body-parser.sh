#!/usr/bin/env bash
# Ubuntu/systemd only. Default is read-only; --apply changes dashboard.service.
set -Eeuo pipefail
umask 077
service=dashboard.service
mode=${1:---check}
health=${2:-http://127.0.0.1:3000/health}
[[ "$mode" == --check || "$mode" == --apply ]] || {
    echo 'Usage: sudo bash upgrade-body-parser.sh [--check|--apply] [http://127.0.0.1:PORT/health]' >&2
    exit 2
}
[[ "$health" =~ ^http://127\.0\.0\.1:[0-9]+/health$ ]] || exit 2
for tool in systemctl node npm curl realpath readlink cp mv mktemp sha256sum flock cmp journalctl; do
    command -v "$tool" >/dev/null || { echo "Missing command: $tool" >&2; exit 1; }
done
app=$(systemctl show "$service" --property=WorkingDirectory --value)
[[ -n "$app" && "$app" == /* && "$app" != / ]] || {
    echo 'dashboard.service must declare an absolute WorkingDirectory.' >&2; exit 1;
}
app=$(realpath -e -- "$app")
[[ "$app" != / ]] || exit 1
cd -- "$app"
[[ -f package.json && -f package-lock.json && -f server.js && -d node_modules ]] || exit 1
# Refuse links: backups and directory swaps must address this installation only.
for item in package.json package-lock.json server.js node_modules; do
    [[ ! -L "$item" ]] || { echo "Refusing symlink: $item" >&2; exit 1; }
done
systemctl is-active --quiet "$service"
pid=$(systemctl show "$service" --property=MainPID --value)
runtime=$(readlink -f -- "/proc/$pid/exe")
[[ "$(basename -- "$runtime")" == node ]] || {
    echo 'MainPID is not Node.js; check the unit manually.' >&2; exit 1;
}
export PATH="$(dirname -- "$runtime"):$PATH"
[[ "$(realpath -e -- "$(command -v node)")" == "$runtime" ]] || exit 1
node --version
npm ls body-parser --all
[[ "$(curl --fail --silent --show-error --max-time 5 "$health")" == ok ]]
if [[ "$mode" == --check ]]; then
    echo "Read-only checks passed: $app ($service)."
    exit 0
fi
[[ "$EUID" == 0 ]] || { echo 'Use sudo for --apply.' >&2; exit 1; }
exec 9>/run/lock/dashboard-body-parser.lock
flock -n 9 || { echo 'Another upgrade is running.' >&2; exit 1; }
parent=$(dirname -- "$app")
backup=$(mktemp -d "$parent/dashboard-body-parser-backup.XXXXXXXX")
stage=$(mktemp -d "$parent/dashboard-body-parser-stage.XXXXXXXX")
echo "Backup: $backup"
echo "Staging: $stage"
cp -a -- package.json package-lock.json node_modules "$backup/"
cp -a -- package.json package-lock.json "$stage/"
sha256sum server.js > "$backup/server.sha256"
changed=0
rollback() {
    # Prepare the original tree before stopping; retain failed files for diagnosis.
    local restore
    restore=$(mktemp -d "$parent/dashboard-body-parser-restore.XXXXXXXX") || return 1
    cp -a -- "$backup/package.json" "$backup/package-lock.json" "$backup/node_modules" "$restore/" || return 1
    systemctl stop "$service" || return 1
    if [[ -e "$app/node_modules" ]]; then
        mv -- "$app/node_modules" "$backup/failed-node_modules" || return 1
    fi
    cp -a -- "$restore/package.json" "$restore/package-lock.json" "$app/" || return 1
    mv -- "$restore/node_modules" "$app/node_modules" || return 1
    systemctl start "$service" || return 1
    healthy || return 1
    echo "Original dependencies restored from $backup" >&2
}
healthy() {
    local attempt
    for attempt in {1..15}; do
        if systemctl is-active --quiet "$service" &&
           [[ "$(curl --fail --silent --max-time 2 "$health")" == ok ]]; then
            return 0
        fi
        sleep 1
    done
    return 1
}
finish() {
    local result=$?
    trap - EXIT INT TERM
    if (( result != 0 && changed == 1 )); then
        echo 'Upgrade failed; restoring the original dependencies.' >&2
        if ! rollback; then
            echo "ROLLBACK FAILED. Backup retained at $backup; manual recovery required." >&2
        fi
    fi
    exit "$result"
}
trap finish EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
(
    cd -- "$stage"
    npm install --save-exact --ignore-scripts --no-audit --no-fund \
        --fetch-retries=1 --fetch-timeout=30000 body-parser@1.20.9
) > "$backup/npm-install.log" 2>&1 || {
    tail -n 25 "$backup/npm-install.log" >&2; exit 1;
}
# Refuse unrelated manifest/lock changes, including transitive version changes.
node - "$backup" "$stage" <<'NODE'
const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const { createRequire } = require('node:module');
const [before, after] = process.argv.slice(2);
const read = (root, file) => JSON.parse(fs.readFileSync(path.join(root, file)));
const oldManifest = read(before, 'package.json');
const newManifest = read(after, 'package.json');
assert.equal(newManifest.dependencies['body-parser'], '1.20.9');
oldManifest.dependencies['body-parser'] = '1.20.9';
assert.deepEqual(newManifest, oldManifest);
const oldLock = read(before, 'package-lock.json');
const newLock = read(after, 'package-lock.json');
for (const key of Object.keys(newLock)) {
    if (key !== 'packages') assert.deepEqual(newLock[key], oldLock[key]);
}
for (const key of new Set([...Object.keys(oldLock.packages), ...Object.keys(newLock.packages)])) {
    if (/(^|\/)node_modules\/body-parser$/.test(key)) {
        if (newLock.packages[key]) assert.equal(newLock.packages[key].version, '1.20.9');
    } else if (key === '') {
        const oldRoot = structuredClone(oldLock.packages[key]);
        oldRoot.dependencies['body-parser'] = '1.20.9';
        assert.deepEqual(newLock.packages[key], oldRoot);
    } else {
        assert.deepEqual(newLock.packages[key], oldLock.packages[key], `Unrelated change: ${key}`);
    }
}
const load = createRequire(path.join(after, 'package.json'));
const expressLoad = createRequire(load.resolve('express/package.json'));
assert.equal(load('body-parser/package.json').version, '1.20.9');
assert.equal(expressLoad('body-parser/package.json').version, '1.20.9');
console.log('Only body-parser changed; Dashboard and Express resolve 1.20.9.');
NODE
(cd -- "$stage" && npm ls --omit=dev --all) > "$backup/npm-tree.log" 2>&1 || {
    tail -n 25 "$backup/npm-tree.log" >&2; exit 1;
}
node --check server.js
sha256sum --check "$backup/server.sha256"
cmp --silent package.json "$backup/package.json"
cmp --silent package-lock.json "$backup/package-lock.json"
# No live file changes until the installation and dependency checks have passed.
changed=1
systemctl stop "$service"
mv -- node_modules "$backup/original-node_modules"
cp -a -- "$stage/package.json" "$stage/package-lock.json" "$app/"
mv -- "$stage/node_modules" "$app/node_modules"
systemctl start "$service"
healthy
# Check a second time to catch an immediate crash/restart loop.
sleep 3
systemctl is-active --quiet "$service"
[[ "$(curl --fail --silent --show-error --max-time 5 "$health")" == ok ]]
sha256sum --check "$backup/server.sha256"
npm ls body-parser --all
journalctl --unit="$service" --since='2 minutes ago' --no-pager --lines=20
changed=0
echo "Upgrade complete. Retain backup: $backup"
