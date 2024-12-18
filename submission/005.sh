#!/bin/bash

# Create a 1-of-4 P2SH multisig address from the public keys in the four inputs of this tx:
#   `37d966a263350fe747f1c606b159987545844a493dd38d84b070027a895c4517`

# Input: Transaction ID
TXID="37d966a263350fe747f1c606b159987545844a493dd38d84b070027a895c4517"

# Step 1: Get raw transaction details
RAW_TX=$(bitcoin-cli getrawtransaction "$TXID" true)

# Step 2: Extract public keys from inputs
PUBKEYS=()
for INPUT in $(jq -c '.vin[]' <<< "$RAW_TX"); do
  PREV_TXID=$(jq -r '.txid' <<< "$INPUT")
  VOUT=$(jq -r '.vout' <<< "$INPUT")
  PREV_TX=$(bitcoin-cli getrawtransaction "$PREV_TXID" true)

  # Check scriptSig for legacy or txinwitness for SegWit
  SCRIPT_SIG=$(jq -r --arg txid "$PREV_TXID" '.vin[] | select(.txid == $txid) | .scriptSig.asm' <<< "$RAW_TX")
  PUBKEY=$(echo "$SCRIPT_SIG" | grep -Eo '\b(02|03)[0-9A-Fa-f]{64}\b|\b04[0-9A-Fa-f]{128}\b')
  WITNESS=$(jq -r --arg txid "$PREV_TXID" '.vin[] | select(.txid == $txid) | .txinwitness[]' <<< "$RAW_TX")

  if [ -z "$PUBKEY" ]; then
    PUBKEY=$(echo "$WITNESS" | grep -Eo '\b(02|03)[0-9A-Fa-f]{64}\b|\b04[0-9A-Fa-f]{128}\b')
  fi

  if [[ -n "$PUBKEY" ]]; then
    PUBKEYS+=("$PUBKEY")
  fi
done

if [ "${#PUBKEYS[@]}" -ne 4 ]; then
  echo "Error: Expected 4 public keys, but found ${#PUBKEYS[@]}." >&2
  exit 1
fi

# Step 3: Create the P2SH address
PUBKEYS_JSON=$(printf '%s\n' "${PUBKEYS[@]}" | jq -R . | jq -s .)
MULTISIG_ADDRESS=$(bitcoin-cli createmultisig 1 "$PUBKEYS_JSON")
P2SH_ADDRESS=$(jq -r '.address' <<< "$MULTISIG_ADDRESS")

# Display the final address
echo "$P2SH_ADDRESS"
