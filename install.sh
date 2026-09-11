#!/usr/bin/env bash

REPO_URL="https://github.com/akopdev/diskette.git"
REPO_DIR="/srv/diskette"
BIN_LINK="/usr/local/bin/diskette"


if [ ! -d "$REPO_DIR" ]; then
  if ! command -v git >/dev/null 2>&1; then
    sudo apt-get update
    sudo apt-get install -y git
  fi
	sudo mkdir -p "$REPO_DIR"
	sudo chown "$(id -un)":"$(id -gn)" "$REPO_DIR"
	git clone "$REPO_URL" "$REPO_DIR"
fi

chmod +x "$REPO_DIR/bin/diskette"
sudo ln -sf "$REPO_DIR/bin/diskette" "$BIN_LINK"

if [ ! -f "$REPO_DIR/.env" ]; then
	cp "$REPO_DIR/.env.example" "$REPO_DIR/.env"
	echo "You need to config server first."
	read -n 1 -s -r -p "Press any key to continue..."
	echo
	vi "$REPO_DIR/.env"
fi

"$BIN_LINK" install
