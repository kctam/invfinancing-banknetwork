echo "==================="
echo "Teardown everything"
echo "==================="
cd ./bank-network
docker-compose -f docker-compose-cli.yaml -f docker-compose-ca.yaml down -v
docker rm $(docker ps -aq)
docker rmi $(docker images dev-* -q)
echo
echo "================="
echo "Teardown complete"
echo "================="