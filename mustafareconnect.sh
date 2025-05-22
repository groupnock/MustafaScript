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
  tmux kill-session -t nock-miner
  echo "✅ tmux session 'nock-miner' killed."
else
  echo "⚠️ tmux session not found. Trying pkill..."
  pkill -f nockchain && echo "✅ Process killed." || echo "⚠️ No running nockchain process."
fi

echo "🧹 Removing old socket files..."
rm -rf "$PROJECT_DIR/.socket"

echo "🛠 Updating Makefile..."
if [ -f "$MAKEFILE" ]; then
  if grep -q '^export MINING_PUBKEY :=' "$MAKEFILE"; then
    sed -i "s/^export MINING_PUBKEY := .*/export MINING_PUBKEY := $NEW_PUBKEY/" "$MAKEFILE"
    echo "✅ Updated MINING_PUBKEY in Makefile."
  else
    echo "export MINING_PUBKEY := $NEW_PUBKEY" >> "$MAKEFILE"
    echo "✅ Added MINING_PUBKEY to Makefile."
  fi
else
  echo "❌ Makefile not found at $MAKEFILE"
fi

echo "🛠 Updating .env..."
if [ -f "$ENVFILE" ]; then
  if grep -q '^MINING_PUBKEY=' "$ENVFILE"; then
    sed -i "s/^MINING_PUBKEY=.*/MINING_PUBKEY=$NEW_PUBKEY/" "$ENVFILE"
    echo "✅ Updated MINING_PUBKEY in .env."
  else
    echo "MINING_PUBKEY=$NEW_PUBKEY" >> "$ENVFILE"
    echo "✅ Added MINING_PUBKEY to .env."
  fi
else
  echo "MINING_PUBKEY=$NEW_PUBKEY" > "$ENVFILE"
  echo "✅ Created .env with MINING_PUBKEY."
fi

echo "🚀 Starting miner in tmux..."
cd "$PROJECT_DIR" || { echo "❌ Failed to cd into $PROJECT_DIR"; exit 1; }
tmux new-session -d -s nock-miner "$MINER_BIN --mining-pubkey $NEW_PUBKEY --mine"

sleep 1
if tmux has-session -t nock-miner 2>/dev/null; then
  echo "✅ Miner started in tmux session: nock-miner"
else
  echo "❌ Failed to start miner in tmux."
fi

echo "✅ Script finished. You can attach with: tmux attach -t nock-miner"
