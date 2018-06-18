#!/bin/bash

# ./byfn.sh -m down
sudo rm -r ./fabric-ca-server/ca1/msp
sudo rm -r ./fabric-ca-server/ca2/msp
# sudo rm -r ./fabric-ca-server/ca3/msp
# sudo rm -r ./fabric-ca-server/ca4/msp
sudo rm ./fabric-ca-server/ca1/fabric-ca-server.db
sudo rm ./fabric-ca-server/ca2/fabric-ca-server.db
# sudo rm ./fabric-ca-server/ca3/fabric-ca-server.db
# sudo rm ./fabric-ca-server/ca4/fabric-ca-server.db
sleep 2
./byfn.sh -m up -s couchdb
rm -r ~/Desktop/client-application-fabric/my-app/client-sdk-fabric/store-Path
rm -r ~/Desktop/client-application-fabric/my-app/client-sdk-fabric/store-Path1
rm -r ~/Desktop/client-application-fabric/my-app/client-sdk-fabric/store-Path2
rm -r ~/Desktop/client-application-fabric/my-app/client-sdk-fabric/store-Path3
rm -r ~/Desktop/client-application-fabric/my-app/client-sdk-fabric/store-Path4
# cd ~/Desktop/client-application-fabric/my-app/
# yarn dev
# cd ~/Desktop/oauth
# nodemon .