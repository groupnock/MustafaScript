#!/bin/bash

# === REQUIRED: Set your new pubkey on a single line ===
NEW_PUBKEY=39wNZh9bkXFvp52LgeZuYsjdkv9NaG6E5PRtX3g4HoUmmjRvAVJUFmF7Zx4fMK3tqKMHTxdcZTW6CS8kKnNjfVm6YiRr7dEFWUTSzWPukcgoUNmQsUo1QCW
ugPQW8Ljcnraz

# === CONFIG ===
PROJECT_DIR="$HOME/nockchain"
MAKEFILE="$PROJECT_DIR/Makefile"
ENVFILE="$PROJECT_DIR/.env"
MINER_BIN="$PROJECT_DIR/target/release/nockchain"

cd "$PROJECT_DIR" || { echo "❌ Failed to enter project directory: $PROJECT_DIR"; exit 1; }

echo "🔧 Killing miner if running..."
if tmux has-session -t nock-miner 2>/dev/null; then
  tmux kill-session -t nock-miner
  echo "✅ tmux session 'nock-miner' killed."
else
  pkill -f nockchain && echo "✅ Killed process." || echo "⚠️ No miner process found."
fi

echo "🧹 Removing socket files..."
rm -rf .socket

echo "🛠 Updating Makefile..."
if grep -q '^export MINING_PUBKEY :=' "$MAKEFILE"; then
  awk -v key="$NEW_PUBKEY" '
    {if ($0 ~ /^export MINING_PUBKEY :=/) print "export MINING_PUBKEY := " key;
     else print $0}' "$MAKEFILE" > "$MAKEFILE.tmp" && mv "$MAKEFILE.tmp" "$MAKEFILE"
  echo "✅ Makefile pubkey updated."
else
  echo "export MINING_PUBKEY := $NEW_PUBKEY" >> "$MAKEFILE"
  echo "✅ Makefile pubkey added."
fi

echo "🛠 Updating .env..."
if grep -q '^MINING_PUBKEY=' "$ENVFILE"; then
  awk -v key="$NEW_PUBKEY" '
    {if ($0 ~ /^MINING_PUBKEY=/) print "MINING_PUBKEY=" key;
     else print $0}' "$ENVFILE" > "$ENVFILE.tmp" && mv "$ENVFILE.tmp" "$ENVFILE"
  echo "✅ .env pubkey updated."
else
  echo "MINING_PUBKEY=$NEW_PUBKEY" >> "$ENVFILE"
  echo "✅ .env pubkey added."
fi

echo "🚀 Starting miner in tmux..."
tmux new-session -d -s nock-miner "$MINER_BIN --mining-pubkey $NEW_PUBKEY --mine"

sleep 1
if tmux has-session -t nock-miner 2>/dev/null; then
  echo "✅ Miner is running inside tmux session: nock-miner"
else
  echo "❌ Miner failed to launch in tmux."
fi
