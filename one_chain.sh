#!/bin/sh

set -ex

display_usage() {
	echo "\nMissing $1 parameter. Please check if all parameters were specified."
	echo "\nUsage: ./one-chain [BINARY] [CHAIN_ID] [CHAIN_DIR] [RPC_PORT] [P2P_PORT] [PROFILING_PORT] [GRPC_PORT]"
  echo "\nExample: ./one-chain $BINARY test-chain-id ./data 26657 26656 6060 9090 \n"
  exit 1
}

KEYRING='--keyring-backend=test'
SILENT=1

redirect() {
  if [ "$SILENT" -eq 1 ]; then
    "$@" > /dev/null 2>&1
  else
    "$@"
  fi
}

BINARY=$1
CHAINID=$2
CHAINDIR=$3
RPCPORT=$4
P2PPORT=$5
PROFPORT=$6
GRPCPORT=$7
RESTPORT=$8

if [ -z "$1" ]; then
  display_usage "[BINARY] ($BINARY|akash)"
fi

if [ -z "$2" ]; then
  display_usage "[CHAIN_ID]"
fi

if [ -z "$3" ]; then
  display_usage "[CHAIN_DIR]"
fi

if [ -z "$4" ]; then
  display_usage "[RPC_PORT]"
fi

if [ -z "$5" ]; then
  display_usage "[P2P_PORT]"
fi

if [ -z "$6" ]; then
  display_usage "[PROFILING_PORT]"
fi

if [ -z "$7" ]; then
  display_usage "[GRPC_PORT]"
fi

if [ -z "$8" ]; then
  display_usage "[REST_PORT]"
fi

echo "Creating $BINARY instance: home=$CHAINDIR | chain-id=$CHAINID | p2p=:$P2PPORT | rpc=:$RPCPORT | profiling=:$PROFPORT | grpc=:$GRPCPORT"

# Add dir for chain, exit if error
if ! mkdir -p $CHAINDIR/$CHAINID 2>/dev/null; then
    echo "Failed to create chain folder. Aborting..."
    exit 1
fi

# Build genesis file incl account for passed address
chain_one_coins="100000000000000000000stake,100000000000umuon,100000000000test,1000000000000000000000000aevmos"
chain_two_coins="100000000000000000000stake,100000000000umuon,1000000000000000000000000aevmos"
delegate="100000000000000000000stake"

$BINARY --home $CHAINDIR/$CHAINID --chain-id $CHAINID init $CHAINID
$BINARY --home $CHAINDIR/$CHAINID keys add validator $KEYRING --output json > $CHAINDIR/$CHAINID/validator_seed.json
$BINARY --home $CHAINDIR/$CHAINID keys add testkey $KEYRING --output json > $CHAINDIR/$CHAINID/key_seed.json
$BINARY --home $CHAINDIR/$CHAINID add-genesis-account $($BINARY --home $CHAINDIR/$CHAINID keys $KEYRING show testkey -a) $chain_one_coins
$BINARY --home $CHAINDIR/$CHAINID add-genesis-account $($BINARY --home $CHAINDIR/$CHAINID keys $KEYRING show validator -a) $chain_two_coins
$BINARY --home $CHAINDIR/$CHAINID gentx validator $delegate $KEYRING --chain-id $CHAINID
$BINARY --home $CHAINDIR/$CHAINID collect-gentxs
$BINARY --home $CHAINDIR/$CHAINID config keyring-backend test
#jq '.app_state.admin.admins.admins = ["'$($BINARY --home $CHAINDIR/$CHAINID keys show testkey -a)'"]' $CHAINDIR/$CHAINID/config/genesis.json > tmp.json && mv tmp.json $CHAINDIR/$CHAINID/config/genesis.json
jq '.app_state.gov.voting_params.voting_period = "10s"' $CHAINDIR/$CHAINID/config/genesis.json > tmp.json && mv tmp.json $CHAINDIR/$CHAINID/config/genesis.json
# Check platform
platform='unknown'
unamestr=`uname`
if [ "$unamestr" = 'Linux' ]; then
   platform='linux'
fi

# Set proper defaults and change ports (use a different sed for Mac or Linux)
echo "Change settings in config.toml file..."
if [ $platform = 'linux' ]; then
  sed -i 's#"tcp://127.0.0.1:26657"#"tcp://0.0.0.0:'"$RPCPORT"'"#g' $CHAINDIR/$CHAINID/config/config.toml
  sed -i 's#"tcp://0.0.0.0:26656"#"tcp://0.0.0.0:'"$P2PPORT"'"#g' $CHAINDIR/$CHAINID/config/config.toml
  sed -i 's#"localhost:6060"#"localhost:'"$P2PPORT"'"#g' $CHAINDIR/$CHAINID/config/config.toml
  sed -i 's/timeout_commit = "5s"/timeout_commit = "1s"/g' $CHAINDIR/$CHAINID/config/config.toml
  sed -i 's/timeout_propose = "3s"/timeout_propose = "1s"/g' $CHAINDIR/$CHAINID/config/config.toml
  sed -i 's/index_all_keys = false/index_all_keys = true/g' $CHAINDIR/$CHAINID/config/config.toml
  sed -i 's#"tcp://0.0.0.0:1317"#"tcp://0.0.0.0:'"$RESTPORT"'"#g' $CHAINDIR/$CHAINID/config/app.toml
  sed -i 's#"tcp://localhost:26657"#"tcp://localhost:'"$RPCPORT"'"#g' $CHAINDIR/$CHAINID/config/client.toml


  # sed -i '' 's#index-events = \[\]#index-events = \["message.action","send_packet.packet_src_channel","send_packet.packet_sequence"\]#g' $CHAINDIR/$CHAINID/config/app.toml
else
  sed -i '' 's#"tcp://127.0.0.1:26657"#"tcp://0.0.0.0:'"$RPCPORT"'"#g' $CHAINDIR/$CHAINID/config/config.toml
  sed -i '' 's#"tcp://0.0.0.0:26656"#"tcp://0.0.0.0:'"$P2PPORT"'"#g' $CHAINDIR/$CHAINID/config/config.toml
  sed -i '' 's#"localhost:6060"#"localhost:'"$P2PPORT"'"#g' $CHAINDIR/$CHAINID/config/config.toml
  sed -i '' 's/timeout_commit = "5s"/timeout_commit = "1s"/g' $CHAINDIR/$CHAINID/config/config.toml
  sed -i '' 's/timeout_propose = "3s"/timeout_propose = "1s"/g' $CHAINDIR/$CHAINID/config/config.toml
  sed -i '' 's/index_all_keys = false/index_all_keys = true/g' $CHAINDIR/$CHAINID/config/config.toml
  sed -i '' 's#"tcp://0.0.0.0:1317"#"tcp://0.0.0.0:'"$RESTPORT"'"#g' $CHAINDIR/$CHAINID/config/app.toml
  sed -i '' 's#"tcp://localhost:26657"#"tcp://localhost:'"$RPCPORT"'"#g' $CHAINDIR/$CHAINID/config/client.toml
  # sed -i '' 's#index-events = \[\]#index-events = \["message.action","send_packet.packet_src_channel","send_packet.packet_sequence"\]#g' $CHAINDIR/$CHAINID/config/app.toml
fi

sleep 1
# Start the gaia
echo "$BINARY --home $CHAINDIR/$CHAINID start --pruning=nothing --grpc-web.enable=false --grpc.address=0.0.0.0:$GRPCPORT &" | bash - > $CHAINDIR/$CHAINID.log 2>&1
#$BINARY --home $CHAINDIR/$CHAINID start --pruning=nothing --grpc-web.enable=false --grpc.address=0.0.0.0:$GRPCPORT > $CHAINDIR/$CHAINID.log 2>&1