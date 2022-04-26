#!/bin/bash

KEYS_DIR="/"

FILE_ETH_KEYS="$KEYS_DIR/validator-eth-keys"

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

for (( i=0; i<${#ETH_ADDRS[@]}; i++ )); do
	jq --arg ADDR $ETH_ADDRS[$i] '.alloc."\($ADDR)".balance="0x1337000000000000000000"' /ETHGenesis.json > /INPUT.tmp && mv /INPUT.tmp /ETHGenesis.json
done
