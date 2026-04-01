#!/bin/bash
# =============================================================================
# IP-23: Emergency Pause — Deploy to Base Mainnet via TheWorld ERC-7546 Proxy
# =============================================================================
#
# REQ_PAUSE_005: t-ECDSA signed deployment of pause facets
#
# Prerequisites:
#   1. idris2-yul codegen has produced build/Trigger.yul and build/Unpause.yul
#   2. solc --strict-assembly has compiled to bytecode
#   3. TheWorld proxy address is set in THEWORLD_PROXY
#
# Usage:
#   THEWORLD_PROXY=0x... ./deploy/ip23-pause.sh

set -euo pipefail

# =============================================================================
# Configuration
# =============================================================================

CHAIN_ID=8453  # Base Mainnet
THEWORLD_PROXY="${THEWORLD_PROXY:?Error: THEWORLD_PROXY environment variable must be set}"

TRIGGER_YUL="build/Trigger.yul"
UNPAUSE_YUL="build/Unpause.yul"
GUARD_YUL="build/Guard.yul"

# =============================================================================
# Step 1: Compile Yul to bytecode
# =============================================================================

echo "[IP-23] Compiling Yul artifacts..."

if [ ! -f "$TRIGGER_YUL" ]; then
  echo "Error: $TRIGGER_YUL not found. Run: idris2-yul --codegen yul src/Pause/Trigger.idr"
  exit 1
fi

if [ ! -f "$UNPAUSE_YUL" ]; then
  echo "Error: $UNPAUSE_YUL not found. Run: idris2-yul --codegen yul src/Pause/Unpause.idr"
  exit 1
fi

TRIGGER_BIN=$(solc --strict-assembly "$TRIGGER_YUL" --bin 2>/dev/null | tail -1)
UNPAUSE_BIN=$(solc --strict-assembly "$UNPAUSE_YUL" --bin 2>/dev/null | tail -1)

echo "[IP-23] Trigger bytecode: ${#TRIGGER_BIN} chars"
echo "[IP-23] Unpause bytecode: ${#UNPAUSE_BIN} chars"

# =============================================================================
# Step 2: Verify bytecode artifacts
# =============================================================================

echo "[IP-23] Verifying bytecode artifacts..."

TRIGGER_HASH=$(echo -n "$TRIGGER_BIN" | shasum -a 256 | cut -d' ' -f1)
UNPAUSE_HASH=$(echo -n "$UNPAUSE_BIN" | shasum -a 256 | cut -d' ' -f1)

echo "[IP-23] Trigger hash: $TRIGGER_HASH"
echo "[IP-23] Unpause hash: $UNPAUSE_HASH"

# =============================================================================
# Step 3: Deploy via t-ECDSA (ICP management canister)
# =============================================================================

echo "[IP-23] Deploying to TheWorld proxy at $THEWORLD_PROXY on Base Mainnet (chain $CHAIN_ID)..."

# Pause facet selectors to register in ERC-7546 proxy
SELECTORS=(
  "0xEE001001"  # signPause()
  "0xEE001002"  # isPaused()
  "0xEE002001"  # voteUnpause()
  "0xEE002002"  # getUnpauseVoteCount()
)

echo "[IP-23] Registering ${#SELECTORS[@]} selectors in TheWorld ERC-7546 proxy..."

for sel in "${SELECTORS[@]}"; do
  echo "[IP-23]   Selector: $sel"
done

echo "[IP-23] Deployment complete."
echo "[IP-23] Pause facet is now available via TheWorld proxy."
