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

DELAY=1
# : ${CHANNEL_NAME:="mychannel"}
# : ${TIMEOUT:="60"}
COUNTER=1
MAX_RETRY=5
ORDERER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

# verify the result of the end-to-end test
verifyResult () {
	if [ $1 -ne 0 ] ; then
		echo "!!!!!!!!!!!!!!! "$2" !!!!!!!!!!!!!!!!"
    echo "========= ERROR !!! FAILED to execute End-2-End Scenario ==========="
		echo
   		exit 1
	fi
}

setGlobals () {

	if [ "$1" -eq 0 ]
	then
		CORE_PEER_LOCALMSPID="Org1MSP"
		CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
		CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
		CORE_PEER_ADDRESS=peer0.org1.example.com:7051
	elif [ "$1" -eq 1 ]
	then
		CORE_PEER_LOCALMSPID="Org2MSP"
		CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
		CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
		CORE_PEER_ADDRESS=peer0.org2.example.com:7051
	else
		CORE_PEER_LOCALMSPID="Org3MSP"
		CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org3.example.com/peers/peer0.org3.example.com/tls/ca.crt
		CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org3.example.com/users/Admin@org3.example.com/msp
		CORE_PEER_ADDRESS=peer0.org3.example.com:7051
	fi

	env |grep CORE
}

createChannel() {
	echo "VALUE"$1
	setGlobals $1

  if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
		peer channel create -o orderer.example.com:7050 -c mychannel$(($1 + 1)) -f ./channel-artifacts/channel$(($1 + 1)).tx >&log.txt
	  else
		peer channel create -o orderer.example.com:7050 -c mychannel$(($1 + 1)) -f ./channel-artifacts/channel$(($1 + 1)).tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA >&log.txt
		  fi
	res=$?
	cat log.txt
	verifyResult $res "Channel$(($1 + 1)) creation failed"
	echo "===================== Channel $(($1 + 1)) is created successfully ===================== "
	echo
}

updateAnchorPeers() {
  setGlobals $1

	if [ $1 -eq 0 ]
    then
		CHANNEL_NAME="mychannel1"
    elif [ $1 -eq 1 ]
    then
		CHANNEL_NAME="mychannel2"
	else
		CHANNEL_NAME="mychannel3"
	fi

  	if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
		peer channel update -o orderer.example.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/${CORE_PEER_LOCALMSPID}anchors.tx >&log.txt
	else
		peer channel update -o orderer.example.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/${CORE_PEER_LOCALMSPID}anchors.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA >&log.txt
	fi
	res=$?
	cat log.txt
	verifyResult $res "Anchor peer update failed"
	echo "===================== Anchor peers for org \"$CORE_PEER_LOCALMSPID\" on \"$CHANNEL_NAME\" is updated successfully ===================== "
	sleep $DELAY
	echo
}

## Sometimes Join takes time hence RETRY atleast for 5 times
joinWithRetry () {

	setGlobals $1

	if [ $1 -eq 0 ]
    then
		BLOCK_NAME="mychannel1.block"
    elif [ $1 -eq 1 ]
    then
		BLOCK_NAME="mychannel2.block"
	else
		BLOCK_NAME="mychannel3.block"
	fi

    PEER=0

	peer channel join -b $BLOCK_NAME  >&log.txt
	
	res=$?
	cat log.txt
	if [ $res -ne 0 -a $COUNTER -lt $MAX_RETRY ]; then
		COUNTER=` expr $COUNTER + 1`
		echo "PEER$1 failed to join the channel, Retry after 2 seconds"
		sleep $DELAY
		joinWithRetry $1
	else
		COUNTER=1
	fi
	
  verifyResult $res "After $MAX_RETRY attempts, PEER$PEER has failed to Join the Channel$(($ch + 1))"
}

joinChannel () {
	for ch in 0 1 2; do
		setGlobals $ch
		joinWithRetry $ch

        PEER=0
        CHANNEL=$(($ch + 1))

        echo "===================== PEER$PEER joined on the channel: mychannel$CHANNEL ===================== "
        sleep $DELAY
        echo
	done
}

installChaincode () {

	setGlobals $1

    PEER=0

	peer chaincode install -n mycc -v 1.0 -p github.com/hyperledger/fabric/examples/chaincode/go/chaincode_example02 >&log.txt
	
	res=$?
	cat log.txt
        verifyResult $res "Chaincode installation on remote peer PEER$PEER has Failed"
	echo "===================== Chaincode is installed on remote peer PEER$PEER ORG $(($1 + 1)) ===================== "
	echo
}

instantiateChaincode () {
	setGlobals $1

	if [ $1 -eq 0 -o $1 -eq 1 ] ; then
		PEER=$1
		CHANNEL_NAME="mychannel1"
	else
		PEER=$(($1 - 2))
		CHANNEL_NAME="mychannel2"
	fi

	# while 'peer chaincode' command can get the orderer endpoint from the peer (if join was successful),
	# lets supply it directly as we know it using the "-o" option
	if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
		peer chaincode instantiate -o orderer.example.com:7050 -C $CHANNEL_NAME -n mycc -v 1.0 -c '{"Args":["init","a","100","b","200"]}' >&log.txt # -P "OR	('Org1MSP.member','Org2MSP.member')"
	
	else
		peer chaincode instantiate -o orderer.example.com:7050 --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n mycc -v 1.0 -c '{"Args":["init","a","100","b","200"]}' >&log.txt # -P "OR	('Org1MSP.member','Org2MSP.member')" 
	fi
	res=$?
	cat log.txt
	verifyResult $res "Chaincode instantiation on PEER$PEER on channel '$CHANNEL_NAME' failed"
	echo "===================== Chaincode Instantiation on PEER$PEER on channel '$CHANNEL_NAME' is successful ===================== "
	echo
}

chaincodeQuery () {

	setGlobals $1

	if [ $1 -eq 0 -o $1 -eq 1 ] ; then
		PEER=$1
		CHANNEL_NAME="mychannel1"
	else
		PEER=$(($1 - 2))
		CHANNEL_NAME="mychannel2"
	fi


  echo "===================== Querying on PEER$PEER on channel '$CHANNEL_NAME'... ===================== "

  local rc=1
  local starttime=$(date +%s)

  # continue to poll
  # we either get a successful response, or reach TIMEOUT
  while test "$(($(date +%s)-starttime))" -lt "$TIMEOUT" -a $rc -ne 0
  do
     sleep $DELAY
     echo "Attempting to Query PEER$PEER ...$(($(date +%s)-starttime)) secs"
     peer chaincode query -C $CHANNEL_NAME -n mycc -c '{"Args":["query","a"]}' >&log.txt
     test $? -eq 0 && VALUE=$(cat log.txt | awk '/Query Result/ {print $NF}')
     test "$VALUE" = "$2" && let rc=0
  done
  echo
  cat log.txt
  if test $rc -eq 0 ; then
	echo "===================== Query on PEER$PEER on channel '$CHANNEL_NAME' is successful ===================== "
  else
	echo "!!!!!!!!!!!!!!! Query result on PEER$PEER is INVALID !!!!!!!!!!!!!!!!"
        echo "================== ERROR !!! FAILED to execute End-2-End Scenario =================="
	echo
	exit 1
  fi
}

chaincodeInvoke () {
	PEER=$1
	setGlobals $PEER
	# while 'peer chaincode' command can get the orderer endpoint from the peer (if join was successful),
	# lets supply it directly as we know it using the "-o" option
	if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
		peer chaincode invoke -o orderer.example.com:7050 -C $CHANNEL_NAME -n mycc -c '{"Args":["invoke","a","b","10"]}' >&log.txt
	else
		peer chaincode invoke -o orderer.example.com:7050  --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n mycc -c '{"Args":["invoke","a","b","10"]}' >&log.txt
	fi
	res=$?
	cat log.txt
	verifyResult $res "Invoke execution on PEER$PEER failed "
	echo "===================== Invoke transaction on PEER$PEER on channel '$CHANNEL_NAME' is successful ===================== "
	echo
}

## Create channel
echo "Creating channels..."
#org1 channel
createChannel 0
# #org2 channel
createChannel 1
# #org3 channel
createChannel 2

# # ## Join all the peers to the channel
echo "Having all peers join the channel..."
joinChannel

# # # ## Set the anchor peers for each org in the channel
echo "Updating anchor peers for org1..."
updateAnchorPeers 0
echo "Updating anchor peers for org2..."
updateAnchorPeers 1
echo "Updating anchor peers for org3..."
updateAnchorPeers 2

# # # ## Install chaincode on Peer0/Org1 and Peer2/Org2  TODO
echo "Installing chaincode on peer0/org1..."
installChaincode 0
echo "Install chaincode on peer0/org2..."
installChaincode 1
echo "Installing chaincode on peer0/org3..."
installChaincode 2

# # # # #Instantiate chaincode on Peer0/Org2
# echo "Instantiating chaincode on org2/peer0..."
# instantiateChaincode 2

# # # #Query on chaincode on Peer0/Org2
#   echo "Querying chaincode on org2/peer0..."
#   chaincodeQuery 2 100

# # # #Query on chaincode on Peer1/Org2
#   echo "Querying chaincode on org2/peer1..."
#   chaincodeQuery 3 100

# # # # #Query on chaincode on Peer1/Org1
#    echo "Querying chaincode on org1/peer0..."
#    chaincodeQuery 1 100

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

#TODO??????
#exit 0
