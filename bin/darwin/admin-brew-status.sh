#!/usr/bin/env bash
set -Eeuo pipefail

echo "doctor ===="
brew doctor

echo ""

echo "linkage ===="
brew linkage

echo ""

echo "leaves ===="
brew leaves

echo ""

echo "dependency tree ===="
brew deps --installed --tree

echo ""

echo "versions ===="
brew list --versions

echo ""

echo "missing ===="
brew missing

echo ""

echo "outdated ===="
brew outdated
brew cask outdated

echo ""

echo "info ===="
brew info
