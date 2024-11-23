# How many new outputs were created by block 123,456?

block_hash=$(bitcoin-cli getblockhash 123456)
block=$(bitcoin-cli getblock "$block_hash")
tx_ids=$(echo "$block" | jq -r '.tx[]')

total_outputs=0

for txid in $tx_ids; do
  tx=$(bitcoin-cli getrawtransaction "$txid" true)
  outputs=$(echo "$tx" | jq '.vout | length')
  total_outputs=$((total_outputs + outputs))
done

echo "$total_outputs"
