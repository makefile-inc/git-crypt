FROM ubuntu:24.04 AS builder

ARG GIT_CRYPTO_VER=0.8.0
ARG BUILD_STATIC=true

COPY sources* /src

RUN <<EOF
#!/usr/bin/env bash

set -Eeuo pipefail

echo "Install deps..."
if ! apt-get update; then
    echo "APT update error"
    exit 1
fi
if ! apt install -y g++ make build-essential libssl-dev; then
    echo "APT install error"
    exit 1
fi

if ! mkdir -p /build; then
    echo "mkdir error"
    exit 1
fi

echo "Consume sources..."

if [ ! -d "/src" ] || [ -z "$(ls -A /src)" ]; then
  echo "Sources dir is not mounted. Clone repo..."
  echo "Install git..."
  
  if ! apt install -y git; then
    echo "APT install git error"
    exit 1
  fi

  echo "Clone branch ${GIT_CRYPTO_VER}..."
  
  if ! git clone --branch ${GIT_CRYPTO_VER} --single-branch https://github.com/AGWA/git-crypt.git /build; then
    echo "git clone error"
    exit 1
  fi
else
  echo "Sources dir mounted. Copy..."
  if ! cp -R /src/* /build; then
    echo "cannot copy source"
    exit 1
  fi
fi

flags="-DOPENSSL_API_COMPAT=0x30000000L"

if [[ "${BUILD_STATIC}" == "true" ]]; then
  flags="$flags -static -ldl"
fi

echo "Build with additional flags: $flags"

cd /build

if ! CXXFLAGS="$flags" make build; then
  echo "Build failed"
  exit 1
fi

ldd_out=""
if ! ldd_out="$(ldd /build/git-crypt 2>&1)"; then
  echo ""
fi

if grep -q "not a dynamic executable" <<<"$ldd_out"; then
  echo "git-crypt is static!"
else
  echo "git-crypt is NOT static!"
fi

echo "You can extract binary from /git-crypt path"
EOF

FROM scratch
COPY --from=builder /build/git-crypt /git-crypt