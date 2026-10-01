#!/usr/bin/env bash
# Upload an FBX to Roblox as a Model through the Open Cloud Assets API and
# print the new asset ID on stdout. Progress and errors go to stderr, so
# `id=$(tools/upload_model.sh assets/models/cone.fbx)` captures just the ID.
#
# Usage: tools/upload_model.sh <file.fbx> [display name]
# Needs: curl, jq, and $ROBLOX_API_KEY (an Open Cloud key with Assets read + write).
set -euo pipefail

API="https://apis.roblox.com/assets/v1"
CREATOR_USER_ID="566042674"
POLL_INTERVAL=2   # seconds between operation checks
POLL_TIMEOUT=180  # seconds before giving up on the operation

die() {
  echo "upload_model: $*" >&2
  exit 1
}

# request <curl args...>: prints the response body; on a non-2xx status prints
# the body to stderr and fails. The key is passed through a file descriptor so
# it never shows up in the process list.
request() {
  local out status
  out=$(curl -sS -w $'\n%{http_code}' \
    -H @<(printf 'x-api-key: %s' "$ROBLOX_API_KEY") "$@") || return 1
  status=${out##*$'\n'}
  out=${out%$'\n'*}
  if [[ $status != 2* ]]; then
    echo "upload_model: HTTP $status: $out" >&2
    return 1
  fi
  printf '%s' "$out"
}

[[ $# -ge 1 && $# -le 2 ]] || die "usage: $0 <file.fbx> [display name]"
file=$1
[[ -f $file ]] || die "no such file: $file"
[[ -n ${ROBLOX_API_KEY:-} ]] || die "ROBLOX_API_KEY is not set"
command -v jq >/dev/null || die "jq is required"

name=${2:-$(basename "${file%.*}")}
metadata=$(jq -n --arg name "$name" --arg userId "$CREATOR_USER_ID" '{
  assetType: "Model",
  displayName: $name,
  description: "Uploaded by tools/upload_model.sh",
  creationContext: {creator: {userId: $userId}}
}')

echo "Uploading $file as \"$name\"..." >&2
op=$(request -X POST "$API/assets" \
  --form-string "request=$metadata" \
  -F "fileContent=@\"$file\";type=model/fbx")

path=$(jq -r '.path // ("operations/" + .operationId)' <<<"$op")
[[ $path == operations/?* ]] || die "no operation in response: $op"

deadline=$((SECONDS + POLL_TIMEOUT))
until [[ $(jq -r '.done // false' <<<"$op") == true ]]; do
  ((SECONDS < deadline)) || die "$path still not done after ${POLL_TIMEOUT}s"
  echo "Waiting for $path..." >&2
  sleep "$POLL_INTERVAL"
  op=$(request "$API/$path")
done

if jq -e '.error' <<<"$op" >/dev/null; then
  die "operation failed: $(jq -c '.error' <<<"$op")"
fi

asset_id=$(jq -r '.response.assetId // empty' <<<"$op")
[[ -n $asset_id ]] || die "operation finished without an assetId: $op"

echo "Moderation: $(jq -r '.response.moderationResult.moderationState // "unknown"' <<<"$op")" >&2
echo "$asset_id"
