#!/bin/sh

rm -rf ./data/ibc-0
killall staykingd
./one_chain.sh staykingd ibc-0 ./data 26657 26656 6060 9090