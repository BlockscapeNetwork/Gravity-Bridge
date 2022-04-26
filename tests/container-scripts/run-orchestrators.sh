#!/bin/bash

KEYS_DIR="/"
PHRASES=()
ETH_KEYS=()
GRAV_CONTRACT=""

NUM_OF_PHRASES=4

while [ $# -gt 0 ]; do
  case $1 in
  --GRAVITY_CONTRACT_ADDR) GRAVITY_CONTRACT_ADDR="$2" ;;
  --KEYS_DIR) KEYS_DIR="$2" ;;
  esac
  shift
done

#compile gbt
cargo build --manifest-path=/gravity/orchestrator/Cargo.toml --release


FILE_CONTRACTS="$KEYS_DIR/contracts"

if [ -z "$GRAVITY_CONTRACT_ADDR" ]; then
  #Gravity deployed at Address -  0x7580bFE88Dd3d07947908FAE12d95872a260F2D8
  # get gravity address
  while read line
  do
    if [[ $line =~ ^Gravity ]]; then
      GRAV_CONTRACT=("$line")
      GRAV_CONTRACT=`expr "$line" : '^Gravity deployed at Address - \(.*\)'`
      break
    fi
  done < "$FILE_CONTRACTS"

fi


FILE_ORCHESTRATOR="$KEYS_DIR/orchestrator-phrases"
FILE_ETH_KEYS="$KEYS_DIR/validator-eth-keys"


# get first NUM_OF_PHRASES phrases
while read line
do
  if [[ ! $line =~ ^\*\*Important ]] && [[ ! $line =~ ^\It\ is ]] && [[ ! -z $line ]]; then
    PHRASES+=("$line")
  fi

  if [[ ${#PHRASES[@]} -eq $NUM_OF_PHRASES ]]; then
    break
  fi
done < "$FILE_ORCHESTRATOR"


# get first NUM_OF_PHRASES eth keys
while read line
do
  if [[ $line =~ ^private ]]; then
    KEY_ONLY=`expr "$line" : '^private\: \(.*\)'`
    ETH_KEYS+=("$KEY_ONLY")
  fi
 
  if [[ ${#ETH_KEYS[@]} -eq $NUM_OF_PHRASES ]]; then
    break
  fi
done < "$FILE_ETH_KEYS"

echo $ETH_KEYS
echo $PHRASES
echo $GRAV_CONTRACT 


# loop and call orchestrator for each phrase
for (( i=0; i<${#PHRASES[@]}; i++ )); do
 mkdir /orch_val_$(($i+1)) # create dir for each orchestrator

 /gravity/orchestrator/target/release/gbt --home "/orch_val_$((i+1))" init #init orchestrators

 
 
 /gravity/orchestrator/target/release/gbt --home "/orch_val_$((i+1))" orchestrator \
    --cosmos-phrase "${PHRASES[$i]}" \
    --ethereum-key "${ETH_KEYS[$i]}" \
    --fees "0stake" \
    --gravity-contract-address $GRAV_CONTRACT \
    --cosmos-grpc "http://localhost:9090" \
    --ethereum-rpc "http://localhost:8545" &> /orch_val_$(($i+1))/logs &
done
