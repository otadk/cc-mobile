#!/bin/bash
set -e

echo "cc-mobile installer"
echo "===================="
echo ""

if [ ! -d /data/data/com.termux ]; then
  echo "Error: This script must run inside Termux on Android."
  echo "Install Termux from https://f-droid.org/packages/com.termux/"
  exit 1
fi

echo "Downloading bootstrap..."
curl -fsSL -o /data/data/com.termux/files/home/bootstrap.sh \
  https://raw.githubusercontent.com/otadk/cc-mobile/main/bootstrap.sh

chmod +x /data/data/com.termux/files/home/bootstrap.sh
exec bash /data/data/com.termux/files/home/bootstrap.sh
