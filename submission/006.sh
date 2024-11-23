# Which tx in block 257,343 spends the coinbase output of block 256,128?

coinbase_txid=$(bitcoin-cli getblockhash 256128 | xargs bitcoin-cli getblock | jq -r '.tx[0]')
spending_txid=$(bitcoin-cli getblockhash 257343 | xargs bitcoin-cli getblock | jq -r '.tx[]' | \
  while read -r tx; do
    if bitcoin-cli getrawtransaction "$tx" true | jq -e ".vin[] | select(.txid == \"$coinbase_txid\")" > /dev/null; then
      echo "$tx"
      break
    fi
  done)

echo "$spending_txid"
