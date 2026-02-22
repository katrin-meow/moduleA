rm -r ./geth
geth  --dev --datadir "./" init genesis.json
geth --datadir "./" --dev --http --http.api web3,eth,net --http.corsdomain "*" --http.port 8545  console
