#!/usr/bin/env sh

if [ -z "$NET_ID" ]; then
  echo "NET_ID env not set. Using default NET_ID=56 (BSC mainnet)"
  NET_ID=56
fi

if [ $NET_ID = "56" ]; then
  NET_NAME="mainnet"
elif [ $NET_ID = "97" ]; then
  NET_NAME="testnet"
else
  echo "Unsupported network $NET_ID. Use either 56 (mainnet) or 97 (testnet)"
  exit 1
fi
echo "Running on BSC $NET_NAME #$NET_ID"

if [ ! -d "/node/geth" ]; then
  echo "Geth data directory not initialized yet. Populating from pre-initialized folder."
  cp  /bsc_$NET_NAME/genesis.json /node/ \
  && cd /node \
  && /usr/local/bin/geth --datadir . init genesis.json
fi

if [ ! -f "/node/config.toml" ]; then
  echo "Geth config not itialized yet. Populating from pre-initialized folder."
  cp /bsc_$NET_NAME/config.toml /node/config.toml
fi


/usr/local/bin/geth --config /node/config.toml --datadir /node "$@"
