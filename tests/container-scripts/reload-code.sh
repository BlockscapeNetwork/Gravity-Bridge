#!/bin/bash
# Number of validators to start
NODES=$1
# what test to execute
TEST_TYPE=$2
ALCHEMY_ID=$3
set -eux

# Stop any currently running gravity, gbt and eth processes
pkill gravityd || true # allowed to fail
pkill geth || true # allowed to fail
pkill gbt || true # allowed to fail

# Wipe filesystem changes
for i in $(seq 1 $NODES);
do
    rm -rf "/validator$i"
    rm -rf "/orch_val_$i"
done

rm "/orchestrator-phrases"
rm "/validator-eth-keys"
rm "/validator-phrases"

rm -rf "/root/.ethereum"

cd /gravity/module/
export PATH=$PATH:/usr/local/go/bin
make
make install
cd /gravity/
tests/container-scripts/setup-validators.sh $NODES
tests/container-scripts/run-testnet.sh $NODES $TEST_TYPE $ALCHEMY_ID

# deploy the ethereum contracts
pushd /gravity/orchestrator/test_runner
DEPLOY_CONTRACTS=1 RUST_BACKTRACE=full TEST_TYPE=$TEST_TYPE NO_GAS_OPT=1 RUST_LOG="INFO,relayer=DEBUG,orchestrator=DEBUG" PATH=$PATH:$HOME/.cargo/bin cargo run --release --bin test-runner

# run orchestrators for our 4 validators
bash /gravity/tests/container-scripts/run-orchestrators.sh &

# This keeps the script open to prevent Docker from stopping the container
# immediately if the nodes are killed by a different process
read -p "Press Return to Close...(don't press enter if you want Docker to keep running)"
