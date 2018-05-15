#!/bin/bash

./byfn.sh -m down
sleep 2
./byfn.sh -m up -s couchdb
# rm -r ~/Desktop/client-application-fabric/my-app/client-sdk-fabric/store-Path
# rm -r ~/Desktop/client-application-fabric/my-app/client-sdk-fabric/store-Path1
# cd ~/Desktop/client-application-fabric/my-app/
# yarn dev