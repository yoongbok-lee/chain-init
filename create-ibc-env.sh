rly tx link demo --home .relayer
key0=$(rly keys show ibc-0 --home .relayer)
key1=$(rly keys show ibc-1 --home .relayer)
rly tx transfer ibc-0 ibc-1 10000000stake $key1 channel-0 --path demo -y 2 -c 10s --home .relayer
staykingd tx ibc-transfer transfer transfer channel-0 $key0 100000000stake -y -b block --home data/ibc-1 --from testkey --node http://localhost:26557
rly tx relay-packets demo channel-0 --home .relayer
ibcdenom=ibc/$(staykingd q ibc-transfer denom-hash transfer/channel-0/stake --home data/ibc-0 | cut -d " " -f2)
echo $ibcdenom
staykingd tx levstakeibc register-host-zone connection-0 sooho stake $ibcdenom channel-0 300 -y -b block --home data/ibc-0 --from testkey