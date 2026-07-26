#!/usr/bin/env bash

set -Eeuo pipefail

dest="${1-}"

if [ -z "$dest" ]; then
    echo "Destination is not passed"
    exit 1
fi

if [ ! -d "$dest" ]; then
    echo "Destination is not dir"
    exit 1
fi

if ! dest="$(realpath "$dest")"; then
    echo "Cannot get realpath for destination"
    exit 1
fi

tag="git-crypt-output:cur"

if ! docker build --progress=plain -t "$tag" .; then
    echo "Destination is not passed"
    exit 1
fi

echo "git-crypt build in image $tag"

id=""

if ! id="$(docker create "$tag" "/no-exec")"; then
    echo "Dummy image is not created!"
    exit 1
fi

echo "Dummy container id $id"

not_copy=""

full_dest="${dest}/git-crypt"

if ! docker cp "$id:/git-crypt" "$full_dest"; then
  not_copy="true"
fi

echo "Remove dummy container $id"

if ! docker rm -v "$id"; then
    echo "Dummy container $id not removed"
fi

if ! docker image rm "$tag"; then
    echo "Dummy container $id not removed"
fi

if [ -n "$not_copy" ]; then
    echo "git-crypt not extracted from image $tag"
    exit 1
fi

chmod 755 "$full_dest" || true

echo "Done! git-crypt now in ${full_dest}"