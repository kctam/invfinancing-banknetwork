cd ./bank-network

# bring up containers
echo "==================="
echo "bring up containers"
echo "==================="
docker-compose -f docker-compose-cli.yaml -f docker-compose-ca.yaml up -d

# bring up invoicechannel and joining all four peers
echo
echo "================================"
echo "bring up and join invoicechannel"
echo "================================"
echo "--create channel genesis block--"
docker exec cli peer channel create -o orderer.example.com:7050 -c invoicechannel -f ./channel-artifacts/channel.tx --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
echo "--join peer0.alpha.example.com to invoicechannel--"
docker exec cli peer channel join -b invoicechannel.block
echo "--join peer1.alpha.example.com to invoicechannel--"
docker exec -e CORE_PEER_ADDRESS=peer1.alpha.example.com:8051 -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/alpha.example.com/peers/peer1.alpha.example.com/tls/ca.crt cli peer channel join -b invoicechannel.block
echo "--join peer0.beta.example.com to invoicechannel--"
docker exec -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/beta.example.com/users/Admin@beta.example.com/msp -e CORE_PEER_ADDRESS=peer0.beta.example.com:9051 -e CORE_PEER_LOCALMSPID="BetaMSP" -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/beta.example.com/peers/peer0.beta.example.com/tls/ca.crt cli peer channel join -b invoicechannel.block
echo "--join peer1.beta.example.com to invoicechannel--"
docker exec -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/beta.example.com/users/Admin@beta.example.com/msp -e CORE_PEER_ADDRESS=peer1.beta.example.com:10051 -e CORE_PEER_LOCALMSPID="BetaMSP" -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/beta.example.com/peers/peer1.beta.example.com/tls/ca.crt cli peer channel join -b invoicechannel.block

# anchor peer update
echo
echo "==================="
echo "update anchor peers"
echo "==================="
echo "--update anchor peer on Alpha--"
docker exec cli peer channel update -o orderer.example.com:7050 -c invoicechannel -f ./channel-artifacts/AlphaMSPanchors.tx --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
echo "--update anchor peer on Beta--"
docker exec -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/beta.example.com/users/Admin@beta.example.com/msp -e CORE_PEER_ADDRESS=peer0.beta.example.com:9051 -e CORE_PEER_LOCALMSPID="BetaMSP" -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/beta.example.com/peers/peer0.beta.example.com/tls/ca.crt cli peer channel update -o orderer.example.com:7050 -c invoicechannel -f ./channel-artifacts/BetaMSPanchors.tx --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

# install chaincode to all four peer nodes
echo
echo "====================="
echo "install chaincode inv"
echo "====================="
echo "--to peer0.alpha.example.com--"
docker exec cli peer chaincode install -n inv -v 1.0 -p github.com/chaincode/invfinancing/
echo "--to peer1.alpha.example.com--"
docker exec -e CORE_PEER_ADDRESS=peer1.alpha.example.com:8051 -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/alpha.example.com/peers/peer1.alpha.example.com/tls/ca.crt cli peer chaincode install -n inv -v 1.0 -p github.com/chaincode/invfinancing
echo "--to peer0.beta.example.com--"
docker exec -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/beta.example.com/users/Admin@beta.example.com/msp -e CORE_PEER_ADDRESS=peer0.beta.example.com:9051 -e CORE_PEER_LOCALMSPID="BetaMSP" -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/beta.example.com/peers/peer0.beta.example.com/tls/ca.crt cli peer chaincode install -n inv -v 1.0 -p github.com/chaincode/invfinancing
echo "--to peer1.beta.example.com--"
docker exec -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/beta.example.com/users/Admin@beta.example.com/msp -e CORE_PEER_ADDRESS=peer1.beta.example.com:10051 -e CORE_PEER_LOCALMSPID="BetaMSP" -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/beta.example.com/peers/peer1.beta.example.com/tls/ca.crt cli peer chaincode install -n inv -v 1.0 -p github.com/chaincode/invfinancing

# instantiate chaincode to invoicechannel
echo
echo "========================="
echo "instantiate chaincode inv"
echo "========================="
docker exec cli peer chaincode instantiate -o orderer.example.com:7050 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C invoicechannel -n inv -v 1.0 -c '{"Args":[]}' -P "AND ('AlphaMSP.peer','BetaMSP.peer')"

cd ..
rm -rf wallet

echo
echo "=========================================="
echo "Everything is Ready. Go for client scripts"
echo "=========================================="