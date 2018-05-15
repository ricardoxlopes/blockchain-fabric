#!/bin/bash

echo
echo " ____    _____      _      ____    _____ "
echo "/ ___|  |_   _|    / \    |  _ \  |_   _|"
echo "\___ \    | |     / _ \   | |_) |   | |  "
echo " ___) |   | |    / ___ \  |  _ <    | |  "
echo "|____/    |_|   /_/   \_\ |_| \_\   |_|  "
echo
echo "Build your first network (BYFN) end-to-end test"
echo
CHANNEL_NAME="$1"
DELAY="$2"
LANGUAGE="$3"
TIMEOUT="$4"
: ${CHANNEL_NAME:="mychannel"}
: ${DELAY:="3"}
: ${LANGUAGE:="golang"}
: ${TIMEOUT:="10"}
LANGUAGE=`echo "$LANGUAGE" | tr [:upper:] [:lower:]`
COUNTER=1
MAX_RETRY=5
ORDERER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer0.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

CC_SRC_PATH="github.com/chaincode/chaincode_example02/go/"
if [ "$LANGUAGE" = "node" ]; then
	CC_SRC_PATH="/opt/gopath/src/github.com/chaincode/chaincode_example02/node/"
fi

echo "Channel name : "$CHANNEL_NAME

# import utils
. scripts/utils.sh

createChannel() {
	PEER=$1
	ORG=$2

	setGlobals $1 $2

	if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
                set -x
		peer channel create -o orderer0.example.com:7050 -c mychannel -f ./channel-artifacts/mychannel.tx >&log.txt
		res=$?
                set +x
	else
				set -x
		peer channel create -o orderer0.example.com:7050 -c mychannel -f ./channel-artifacts/mychannel.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA >&log.txt
		res=$?
				set +x
	fi
	cat log.txt
	verifyResult $res "Channel mychannel creation failed"
	echo "===================== Channel mychannel is created successfully ===================== "
	echo
}

joinChannel () {
	for org in 1 2; do
	    for peer in 0 1; do
			joinChannelWithRetry $peer $org
			echo "===================== peer${peer}.org${org} joined on the mychannel ===================== "
			sleep $DELAY
			echo
	    done
	done
	
	joinChannelWithRetry 0 3
	echo "===================== peer0.org3 joined on the mychannel ===================== "
	sleep $DELAY
	
	echo
	joinChannelWithRetry 0 4
	echo "===================== peer0.pl1 joined on the mychannel ===================== "
	sleep $DELAY
	
	echo
	joinChannelWithRetry 1 4
	echo "===================== peer1.pl1 joined on the mychannel ===================== "
}

## Create channel
echo "Creating channel..."
createChannel 0 1

## Join all the peers to the channel
echo "Having all peers join the channel..."
joinChannel

## Set the anchor peers for each org in the channel
echo "Updating anchor peers for org1..."
updateAnchorPeers 0 1
echo "Updating anchor peers for org2..."
updateAnchorPeers 0 2
echo "Updating anchor peers for org3..."
updateAnchorPeers 0 3
echo "Updating anchor peers for pl1..."
updateAnchorPeers 0 4

## Install chaincode on peer0.org1 and peer0.org2
echo "Installing chaincode on peer0.org1..."
installChaincode 0 1
echo "Installing chaincode on peer1.org1..."
installChaincode 1 1
echo "Installing chaincode on peer0.org2..."
installChaincode 0 2
echo "Installing chaincode on peer1.org2..."
installChaincode 1 2
echo "Installing chaincode on peer0.org3..."
installChaincode 0 3
echo "Installing chaincode on peer0.pl1..."
installChaincode 0 4
echo "Installing chaincode on peer1.pl1..."
installChaincode 1 4

echo "Instantiating chaincode on peer0.org1..."
instantiateChaincode 0 1 '"info","{\"org\":\"Hospital_2\",\"logo\":\"blob_2\",\"source\":\"Hospital_2\"}"'
# echo "Instantiating chaincode on peer0.org2..."
# instantiateChaincode 0 2 '"info1","{\"org\":\"Hospital_2\",\"logo\":\"blob_2\",\"source\":\"Hospital_2\"}"'
# echo "Instantiating chaincode on peer0.org3..."
# instantiateChaincode 0 3 '"info2","{\"org\":\"Hospital_3\",\"logo\":\"blob_3\",\"source\":\"Hospital_3\"}"'
# echo "Instantiating chaincode on peer0.pl1..."
# instantiateChaincode 0 4 '"info3","{\"name\":\"Patient_1\",\"Picture\":\"blob_4\",\"source\":\"Patient_1\"}"'

# echo "QUERY peer0.org1"
# chaincodeQuery 0 1 "record1"
# echo "QUERY peer1.org1"
# chaincodeQuery 1 1 "record1"
# echo "QUERY peer0.org2"
# chaincodeQuery 0 2 "record2"
# echo "QUERY a peer1.org2"
# chaincodeQuery 1 2 "record2"

# # Invoke chaincode on peer0.org1
# echo "Sending invoke transaction on peer0.org1..."
# chaincodeInvoke 0 1

# ## Install chaincode on peer1.org2
# #echo "Installing chaincode on peer1.org2..."
# #installChaincode 1 2

# # Query on chaincode on peer1.org2, check if the result is 90
# #echo "Querying chaincode on peer1.org2..."
# chaincodeQuery 0 1 90
# chaincodeQuery 1 1 90
# chaincodeQuery 0 2 100

# echo "Instantiating chaincode on peer0.org3..."
# instantiateChaincode 0 3

# chaincodeQuery 0 3 100

echo
echo "========= All GOOD, BYFN execution completed =========== "
echo

echo
echo " _____   _   _   ____   "
echo "| ____| | \ | | |  _ \  "
echo "|  _|   |  \| | | | | | "
echo "| |___  | |\  | | |_| | "
echo "|_____| |_| \_| |____/  "
echo

exit 0
