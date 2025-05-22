#!/bin/bash

# === CONFIG ===
NEW_PUBKEY="39wNZh9bkXFvp52LgeZuYsjdkv9NaG6E5PRtX3g4HoUmmjRvAVJUFmF7Zx4fMK3tqKMHTxdcZTW6CS8kKnNjfVm6YiRr7dEFWUTSzWPukcgoUNmQsUo1QCW
ugPQW8Ljcnraz"
PROJECT_DIR="$HOME/nockchain"
cd "$PROJECT_DIR" || { echo "❌ ERROR: Could not enter $PROJECT_DIR"; exit 1; }

MAKEFILE="Makefile"
ENVFILE=".env"
MINER_BIN="./target/release/nockchain"

echo "🔧 Killing miner if running..."
tmux has-session -t nock-miner 2>/dev/null && tmux kill-session -t nock-miner && echo "✅ Killed tmux session." || pkill -f nockchain && echo "✅ Killed process." || echo "⚠️ No miner running."

echo "🧹 Removing socket files..."
rm -rf .socket

echo "🛠 Replacing pubkey in Makefile..."
if grep -q '^export MINING_PUBKEY :=' "$MAKEFILE"; then
  sed -i "s|^export MINING_PUBKEY := .*|export MINING_PUBKEY := $NEW_PUBKEY|" "$MAKEFILE"
  echo "✅ Makefile pubkey updated."
else
  echo "export MINING_PUBKEY := $NEW_PUBKEY" >> "$MAKEFILE"
  echo "✅ Makefile pubkey added."
fi

echo "🛠 Replacing pubkey in .env..."
if grep -q '^MINING_PUBKEY=' "$ENVFILE"; then
  sed -i "s|^MINING_PUBKEY=.*|MINING_PUBKEY=$NEW_PUBKEY|" "$ENVFILE"
  echo "✅ .env pubkey updated."
else
  echo "MINING_PUBKEY=$NEW_PUBKEY" >> "$ENVFILE"
  echo "✅ .env pubkey added."
fi

echo "🚀 Starting miner in tmux..."
tmux new-session -d -s nock-miner "$MINER_BIN --mining-pubkey $NEW_PUBKEY --mine"

sleep 1
if tmux has-session -t nock-miner 2>/dev/null; then
  echo "✅ Miner running in tmux (session: nock-miner)"
else
  echo "❌ Failed to start miner in tmux."
fi
