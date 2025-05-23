
#!/bin/bash

set -euo pipefail  # Safer bash options

### CONFIG
REPO_URL="https://github.com/zorp-corp/nockchain"
PROJECT_DIR="$HOME/nockchain"
PUBKEY="34vkPQCAkbwuNcvBHJ5UhBjss7UKkJqp9MzpY3Wimt8RQkFeKbBDQvNwtDBdvrnftxaHB76amUZrLsfULWrezYemFs8UZyDqeKTkd6FJLLpwmqQp86xsh3gHF8ezqAP3YkUD"
ENV_FILE="$PROJECT_DIR/.env"
MAKEFILE="$PROJECT_DIR/Makefile"
TMUX_SESSION="nock-miner"

echo ""
echo "[!] Purging all files in current working directory..."
rm -rf *
sleep 10  # Safety pause
echo "[✔] Directory cleaned. Continuing..."
echo ""

echo "[+] Nockchain MainNet Bootstrap Starting..."
echo "-------------------------------------------"


### 1. Install Rust Toolchain
echo "[1/7] Installing Rust toolchain..."
if ! command -v cargo &>/dev/null; then
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  export PATH="$HOME/.cargo/bin:$PATH"
fi

### 2. Install System Dependencies
echo "[2/7] Installing system dependencies..."
sudo apt update && sudo apt install -y \
  git \
  make \
  build-essential \
  clang \
  llvm-dev \
  libclang-dev \
  tmux

### 3. Clone Repo & Pull Latest
echo "[3/7] Cloning or updating Nockchain repo..."
if [ ! -d "$PROJECT_DIR" ]; then
  git clone --depth 1 --branch master "$REPO_URL" "$PROJECT_DIR"
else
  cd "$PROJECT_DIR"
  git reset --hard HEAD && git pull origin master
fi
cd "$PROJECT_DIR"

### 4. Create or update .env
echo "[4/7] Setting pubkey in .env..."
cp -f .env_example .env
sed -i "s|^MINING_PUBKEY=.*|MINING_PUBKEY=$PUBKEY|" "$ENV_FILE"
grep "MINING_PUBKEY" "$ENV_FILE"

### 5. Update Makefile with pubkey (if line exists)
echo "[5/7] Patching Makefile with pubkey..."
if grep -q "^export MINING_PUBKEY" "$MAKEFILE"; then
  sed -i "s|^export MINING_PUBKEY.*|export MINING_PUBKEY := $PUBKEY|" "$MAKEFILE"
else
  echo "export MINING_PUBKEY := $PUBKEY" >> "$MAKEFILE"
fi
grep "MINING_PUBKEY" "$MAKEFILE"

### 6. Build Everything
echo "[6/7] Building Nockchain..."
make install-hoonc
make build
make install-nockchain
make install-nockchain-wallet

### 7. Clean previous node data
echo "[7/7] Cleaning old data directory..."
rm -rf "$PROJECT_DIR/.data.nockchain"

### 8. Start Miner using CLI pubkey
echo "[8/8] Launching miner in tmux with your pubkey..."
tmux kill-session -t "$TMUX_SESSION" 2>/dev/null || true
tmux new-session -d -s "$TMUX_SESSION" "cd $PROJECT_DIR && nockchain --mining-pubkey $PUBKEY --mine | tee -a miner.log"

echo ""
echo "✅ Nockchain MainNet Miner launched successfully!"
echo "   - To view miner logs: tmux attach -t $TMUX_SESSION"
echo "   - Wallet PubKey (used + saved): $PUBKEY"
echo ""
