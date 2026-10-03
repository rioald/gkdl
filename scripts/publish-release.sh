#!/bin/bash
# Explicit local publication of an already notarized, verified package.
set -euo pipefail
cd "$(dirname "$0")/.."
[[ $# == 2 ]] || { echo "Usage: $0 PACKAGE_DIRECTORY RELEASE_NOTES.md" >&2; exit 1; }
package=$1
notes=$2
[[ -s "$notes" ]] || { echo 'Release notes are required.' >&2; exit 1; }
[[ -z "$(git status --porcelain)" ]] || { echo 'Commit source changes before publishing.' >&2; exit 1; }
[[ "$(git branch --show-current)" == main ]] || { echo 'Publish from main.' >&2; exit 1; }
version=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Info.plist)
tag="v$version"
archive="$package/gkdl-$version-macos-universal.zip"
ruby scripts/prepare-release.rb "$archive"
python3 - "$package/PACKAGE.json" "$version" "$(git rev-parse HEAD)" <<'PY'
import json, sys
from pathlib import Path
data = json.loads(Path(sys.argv[1]).read_text())
expected = dict(status='notarized', version=sys.argv[2], commit=sys.argv[3], repository='rioald/gkdl')
if data != expected:
    raise SystemExit('Package must be notarized and built from the current source commit.')
PY
origin=$(git remote get-url --push origin)
[[ "$origin" == https://github.com/rioald/gkdl.git || "$origin" == git@github.com:rioald/gkdl.git ]] || {
  echo 'origin must point to rioald/gkdl.' >&2; exit 1;
}
if git rev-parse -q --verify "refs/tags/$tag" >/dev/null; then
  [[ "$(git rev-parse "$tag^{commit}")" == "$(git rev-parse HEAD)" ]] || { echo 'Existing tag targets different source.' >&2; exit 1; }
else
  git tag -a "$tag" -m "gkdl $version"
fi
git push origin main "refs/tags/$tag"
# gh refuses to overwrite an existing release. No --clobber or forced tag updates.
gh release create "$tag" "$archive" "$package/SHA256SUMS" \
  --repo rioald/gkdl --verify-tag --latest --title "gkdl $version" --notes-file "$notes"
