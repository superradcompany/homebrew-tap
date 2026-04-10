#!/bin/sh
# Updates the Homebrew formula with the latest version and SHA256 checksums.
# Usage: scripts/update-formula.sh <version>
#   e.g. scripts/update-formula.sh 0.3.12
set -eu

VERSION="$1"
FORMULA="Formula/microsandbox.rb"
REPO="superradcompany/microsandbox"

if [ ! -f "$FORMULA" ]; then
    echo "Error: $FORMULA not found" >&2
    exit 1
fi

# Download checksums from the release
CHECKSUMS=$(gh release download "v${VERSION}" --repo "$REPO" --pattern 'checksums.sha256' --output -)

get_sha() {
    echo "$CHECKSUMS" | grep "$1" | awk '{print $1}'
}

SHA_DARWIN_AARCH64=$(get_sha "microsandbox-darwin-aarch64.tar.gz")
SHA_LINUX_AARCH64=$(get_sha "microsandbox-linux-aarch64.tar.gz")
SHA_LINUX_X86_64=$(get_sha "microsandbox-linux-x86_64.tar.gz")

if [ -z "$SHA_DARWIN_AARCH64" ] || [ -z "$SHA_LINUX_AARCH64" ] || [ -z "$SHA_LINUX_X86_64" ]; then
    echo "Error: could not find all required checksums" >&2
    exit 1
fi

# Update version
sed -i.bak "s/^  version \".*\"/  version \"${VERSION}\"/" "$FORMULA"

# Update SHA256 checksums (order: darwin-aarch64, linux-aarch64, linux-x86_64)
# Use awk to update the sha256 lines in order of appearance
awk -v sha1="$SHA_DARWIN_AARCH64" \
    -v sha2="$SHA_LINUX_AARCH64" \
    -v sha3="$SHA_LINUX_X86_64" '
BEGIN { count = 0 }
/sha256 "/ {
    count++
    if (count == 1) sub(/"[0-9a-f]{64}"/, "\"" sha1 "\"")
    else if (count == 2) sub(/"[0-9a-f]{64}"/, "\"" sha2 "\"")
    else if (count == 3) sub(/"[0-9a-f]{64}"/, "\"" sha3 "\"")
}
{ print }
' "$FORMULA" > "${FORMULA}.tmp" && mv "${FORMULA}.tmp" "$FORMULA"

rm -f "${FORMULA}.bak"

echo "Updated $FORMULA to version $VERSION"
echo "  darwin-aarch64: $SHA_DARWIN_AARCH64"
echo "  linux-aarch64:  $SHA_LINUX_AARCH64"
echo "  linux-x86_64:   $SHA_LINUX_X86_64"
