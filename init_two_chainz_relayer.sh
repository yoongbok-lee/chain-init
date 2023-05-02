#!/bin/bash
# init_two_chainz_relayer creates two wasmd chains and configures the relayer
set -x

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
DATA_DIR="$(pwd)/data"
RELAYER_CONF="$(pwd)/.relayer"

BINARY_1="staykingd"
BINARY_2="staykingd"

# Stop existing binary processes
killall $BINARY_1
killall $BINARY_2
sleep 2


# Ensure relayer is installed
if ! [ -x "$(which rly)" ]; then
  echo "Error: relayer is not installed." >&2
  exit 1
fi

# Ensure binary 1 is installed
if ! [ -x "$(which staykingd)" ]; then
  echo "Error: staykingd is not installed." >&2
  exit 1
fi

# Ensure binary 2 is installed
if ! [ -x "$(which evmosd)" ]; then
  echo "Error: evmosd is not installed." >&2
  exit 1
fi

# Display software version for testers
echo "BINARY VERSION INFOS:"
$BINARY_1 version --long
$BINARY_2 version --long

# Ensure jq is installed
if [[ ! -x "$(which jq)" ]]; then
  echo "jq (a tool for parsing json in the command line) is required..."
  echo "https://stedolan.github.io/jq/download/"
  exit 1
fi

# Delete data from old runs
rm -rf $DATA_DIR
rm -rf $RELAYER_CONF

set -e

chainid0=ibc-0
chainid1=ibc-1

echo "Generating wasmd configurations..."
mkdir -p $DATA_DIR && cd $DATA_DIR && cd ../
./one_chain.sh $BINARY_1 $chainid0 ./data 26657 26656 6060 9090 1317
./one_chain.sh $BINARY_2 $chainid1 ./data 26557 26556 6161 9191 1318

[ -f $DATA_DIR/$chainid0.log ] && echo "$chainid0 initialized. Watch file $DATA_DIR/$chainid0.log to see its execution."
[ -f $DATA_DIR/$chainid1.log ] && echo "$chainid1 initialized. Watch file $DATA_DIR/$chainid1.log to see its execution."

echo "Removing existing rly configuration.."
rm -rf $RELAYER_CONF

echo "Generating rly configurations..."
rly config init --home $RELAYER_CONF
rly chains add --file configs/chains/$chainid1.json --home $RELAYER_CONF
rly chains add --file configs/chains/$chainid0.json --home $RELAYER_CONF
rly paths add $chainid0 $chainid1 demo --file configs/paths/demo.json --home $RELAYER_CONF

SEED0=$(jq -r '.mnemonic' $DATA_DIR/$chainid0/key_seed.json)
SEED1=$(jq -r '.mnemonic' $DATA_DIR/$chainid1/key_seed.json)
echo "Key $(rly keys restore $chainid0 testkey "$SEED0"  --home $RELAYER_CONF) imported from $chainid0 to relayer..."
echo "Key $(rly keys restore $chainid1 testkey "$SEED1"  --home $RELAYER_CONF) imported from $chainid1 to relayer..."
sleep 2
#temp fix for weird evmos address resolution (prob due to different pubkey type)
# $BINARY_1 tx bank send testkey $(rly keys show $chainid0 testkey --home $RELAYER_CONF) 10000000000000000stake,10000000000000000000aevmos --home $DATA_DIR/$chain0 -y -b block
$BINARY_2 tx bank send $($BINARY_2 keys show testkey -a --home $DATA_DIR/$chainid1) $(rly keys show $chainid1 testkey --home $RELAYER_CONF) \
 10000000000000000stake,10000000000000000000aevmos --home $DATA_DIR/$chainid1 -y -b block --node http://localhost:26557 --gas auto \
 --gas-prices 765625001aevmos --gas-adjustment 1.2 --from testkey

echo "Creating light clients..."
sleep 2
rly start demo --home $RELAYER_CONF