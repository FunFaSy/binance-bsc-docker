#!/usr/bin/env sh

set -e
set -o errexit
#set -o nounset

DATA_DIR=/node
NET_NAME=
NET_ID=
pid=0

init() {
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

  if [ ! -d "$DATA_DIR/geth" ]; then
    echo "Geth data directory not initialized yet. Populating from pre-initialized folder."
    cp "/bsc_$NET_NAME/genesis.json" "$DATA_DIR/" &&
      cd $DATA_DIR &&
      /usr/local/bin/geth --datadir . init genesis.json
  fi

  if [ ! -f "$DATA_DIR/config.toml" ]; then
    echo "Geth config not itialized yet. Populating from pre-initialized folder."
    cp "/bsc_$NET_NAME/config.toml" "$DATA_DIR/config.toml"
  fi

}

# Starts the node(geth) with
# whatever arguments we pass to it ("$@")
start() {
  # first arg is `-f` or `--some-option`
  if [ "${1#-}" != "$1" ]; then
    set -- /usr/local/bin/geth --datadir "$DATA_DIR" --config "$DATA_DIR/config.toml" "$@"
  fi

  if [ "$1" = 'geth' ]; then
    shift # "geth"

    set -- /usr/local/bin/geth --datadir "$DATA_DIR" --config "$DATA_DIR/config.toml" "$@"
  fi

  exec "${@}" &
  pid="$!"

  echo "Running on BSC $NET_NAME #$NET_ID"
}

# Gracefully stops node
stop() {
  if [ $pid -ne 0 ]; then
    echo "Stopping BSC process (PID $pid )"

    # A signal emitted while waiting will make the wait command return code > 128
    # Let's wrap it in a loop that doesn't end before the process is indeed stopped
    while kill -s INT "$pid" >/dev/null 2>&1; do
      sleep 30 &
      wait $pid
    done
  fi

  exit
}

trap stop INT TERM USR1 EXIT

init
start "$@"

wait $pid
exit 0
