binary=staykingd

rly tx link demo --home .relayer
key0=$(rly keys show ibc-0 --home .relayer)
key1=$(rly keys show ibc-1 --home .relayer)
rly tx transfer ibc-0 ibc-1 10000000stake $key1 channel-0 --path demo -y 2 -c 10s --home .relayer
$binary tx ibc-transfer transfer transfer channel-0 $key0 100000000stake -y -b block --home data/ibc-1 --from testkey --node http://localhost:26677
rly tx relay-packets demo channel-0 --home .relayer
ibcdenom=ibc/$($binary q ibc-transfer denom-hash transfer/channel-0/stake --home data/ibc-0 | cut -d " " -f2)
echo $ibcdenom
$binary tx stakeibc register-host-zone connection-0 stake sooho $ibcdenom channel-0 300 -y -b block --home data/ibc-0 --from testkey --gas auto --gas-adjustment 1.5
$binary tx stakeibc add-validator ibc-1 cosmos $($binary --home data/ibc-1 keys show validator --bech=val -a) 10 5 -y -b block --home data/ibc-0 --from testkey --gas auto --gas-adjustment 1.5
$binary tx stakeibc liquid-stake 10000 stake -y -b block --home data/ibc-0 --from testkey --gas auto --gas-adjustment 1.5
rly tx relay-packets demo channel-0 --home .relayer
height=$(staykingd status > tmp.json &&  jq .SyncInfo.latest_block_height tmp.json)
rm tmp.json
heightnum=$(echo $height | tr -d '"')
echo $height
echo $heightnum
upgradeheight=$(($heightnum+20))
jq '.messages[0].plan.height = "'$upgradeheight'"' draft_proposal.json > tmp.json && mv tmp.json proposal.json
$binary tx gov submit-proposal proposal.json -y -b block --home data/ibc-0 --from testkey --gas auto --gas-adjustment 1.5
$binary tx gov vote 1 yes -y -b block --home data/ibc-0 --from validator --gas auto --gas-adjustment 1.5