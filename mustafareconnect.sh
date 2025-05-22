#!/bin/bash

# === CONFIG ===
NEW_PUBKEY="39wNZh9bkXFvp52LgeZuYsjdkv9NaG6E5PRtX3g4HoUmmjRvAVJUFmF7Zx4fMK3tqKMHTxdcZTW6CS8kKnNjfVm6YiRr7dEFWUTSzWPukcgoUNmQsUo1QCW
ugPQW8Ljcnraz"
PROJECT_DIR="$HOME/nockchain"
MAKEFILE="$PROJECT_DIR/Makefile"
ENVFILE="$PROJECT_DIR/.env"
MINER_BIN="$PROJECT_DIR/target/release/nockchain"

echo "🔧 Killing old miner..."
if tmux has-session -t nock-miner 2>/dev/null; then
  echo "🧨 Killing tmux session: nock-miner"
  tmux kill-session -t nock-miner
else
  echo "⚠️ No tmux session found. Using pkill fallback."
  pkill -f nockchain
fi

echo "🧹 Cleaning up socket files..."
rm -rf "$PROJECT_DIR/.socket"

echo "🛠 Updating Makefile MINING_PUBKEY..."
if grep -q '^export MINING_PUBKEY :=' "$MAKEFILE"; then
  sed -i "s/^export MINING_PUBKEY := .*/export MINING_PUBKEY := $NEW_PUBKEY/" "$MAKEFILE"
else
  echo "export MINING_PUBKEY := $NEW_PUBKEY" >> "$MAKEFILE"
fi

echo "🛠 Updating .env MINING_PUBKEY..."
if [ -f "$ENVFILE" ]; then
  if grep -q '^MINING_PUBKEY=' "$ENVFILE"; then
    sed -i "s/^MINING_PUBKEY=.*/MINING_PUBKEY=$NEW_PUBKEY/" "$ENVFILE"
  else
    echo "MINING_PUBKEY=$NEW_PUBKEY" >> "$ENVFILE"
  fi
else
  echo "MINING_PUBKEY=$NEW_PUBKEY" > "$ENVFILE"
fi

echo "🚀 Starting miner in tmux..."
cd "$PROJECT_DIR"
tmux new-session -d -s nock-miner "$MINER_BIN --mining-pubkey $NEW_PUBKEY --mine"

echo "✅ Miner is now running with:"
echo "   nockchain --mining-pubkey $NEW_PUBKEY --mine"
echo "   inside tmux session 'nock-miner'"
