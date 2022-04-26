#!/bin/bash
# Starts the Ethereum testnet chain in the background

# add funds for orchestrator accounts

KEYS_DIR="/"
FILE_ETH_KEYS="$KEYS_DIR/validator-eth-keys"
GENESIS_FILE="/gravity/tests/assets/ETHGenesis.json"


# get first 4 eth addresses
while read line
do
  if [[ $line =~ ^address ]]; then
    KEY_ONLY=`expr "$line" : '^address\: \(.*\)'`
    ETH_ADDRS+=("$KEY_ONLY")
  fi
 
  if [[ ${#ETH_ADDRS[@]} -eq 4 ]]; then
    break
  fi
done < "$FILE_ETH_KEYS"

for CURRENT in ${ETH_ADDRS[@]}; do
 echo "adding eth address to genesis:"
 echo $CURRENT
 jq --arg ADDR $CURRENT '.alloc."\($ADDR)".balance="0x1337000000000000000000"' $GENESIS_FILE > /INPUT.tmp && mv /INPUT.tmp $GENESIS_FILE
done


# init the genesis block
geth --identity "GravityTestnet" \
--nodiscover \
--networkid 15 init $GENESIS_FILE

# etherbase is where rewards get sent
# private key for this address is 0xb1bab011e03a9862664706fc3bbaa1b16651528e5f0e7fbfcbfdd8be302a13e7
geth --identity "GravityTestnet" --nodiscover \
--networkid 15 \
--mine \
--http \
--http.addr="0.0.0.0" \
--http.vhosts="*" \
--http.corsdomain="*" \
--miner.threads=1 \
--nousb \
--verbosity=5 \
--miner.etherbase=0xBf660843528035a5A4921534E156a27e64B231fE &> /geth.log
