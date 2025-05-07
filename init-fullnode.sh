#!/bin/bash

# Configuration variables
GETH_VERSION="1.10.26"
NETWORK_ID=45545  # Must match genesis.json chainId
DATADIR="$HOME/go-ethereum/trrxitte"
GENESIS_FILE="$HOME/go-ethereum/genesis.json"
NODE_PORT=24001
BOOTNODES="enode://48514c63b4d9dbf1d0283bfe6851c17189a690327726cb74985e11a2897547ac58dc9cb0c998f088ae87ff064425501cfb1aae1a2f02f9366ab8118a5bf6bbee@10.154.0.7:24001,enode://93f5de22f836c4e2afb17c3d455852f63598d7a28fbec036d02a6ca4bee1a7ed80da664e52872f618c33a1576423a0dec850ccf0e3e171c7a28533118d52d1f3@34.147.174.188:24001,enode://29462e0152a53ad2c70bd4a06850cc834dc71c1c90d59a29bebee0782b81391bf834c528a53b549a1de62ce1ce569d74b62316cd51e5596e549c9cc8edfe5999@34.142.48.190:24001"  # Replace with actual bootnode enodes
ETHERBASE="0x144a2763e425C80b88A31C2aE398F4e51C79A449"  # Replace with your Ethereum address

# Step 1: Check if Geth is installed and matches version 1.10.26
if ! command -v geth &> /dev/null; then
    echo "Geth not found. Please install Geth version $GETH_VERSION."
    exit 1
fi

GETH_INSTALLED_VERSION=$(geth version | grep "Version: $GETH_VERSION" | wc -l)
if [ $GETH_INSTALLED_VERSION -eq 0 ]; then
    echo "Geth version $GETH_VERSION is required. Installed version does not match."
    exit 1
fi

# Step 2: Verify genesis.json exists
if [ ! -f "$GENESIS_FILE" ]; then
    echo "genesis.json not found at $GENESIS_FILE. Please provide the file."
    exit 1
fi

# Step 3: Create data directory
mkdir -p "$DATADIR"
echo "Created data directory: $DATADIR"

# Step 4: Initialize the full node with genesis.json
echo "Initializing full node at $DATADIR..."
geth --datadir "$DATADIR" init "$GENESIS_FILE"
if [ $? -eq 0 ]; then
    echo "Full node initialized successfully."
else
    echo "Failed to initialize full node. Check $GENESIS_FILE for errors."
    exit 1
fi

# Step 5: Start the full node
echo "Starting full node..."
geth --datadir "$DATADIR" \
     --networkid "$NETWORK_ID" \
     --port "$NODE_PORT" \
     --bootnodes "$BOOTNODES" \
     --http \
     --http.api "eth,net,web3,personal,miner" \
     --http.corsdomain "*" \
     --mine \
     --miner.etherbase "$ETHERBASE" \
     --verbosity 3 \
     console > "$DATADIR/node.log" 2>&1 &

FULLNODE_PID=$!
echo "Full node started with PID $FULLNODE_PID. Logs at $DATADIR/node.log"

# Step 6: Get the node's enode
sleep 5  # Wait for node to start
ENODE=$(geth --datadir "$DATADIR" --exec "admin.nodeInfo.enode" console 2>/dev/null | tr -d '"')
if [ -z "$ENODE" ]; then
    echo "Failed to retrieve node enode. Check $DATADIR/node.log for errors."
else
    echo "Node enode: $ENODE"
    echo "$ENODE" > "$DATADIR/node_enode.txt"
    echo "Node enode saved to $DATADIR/node_enode.txt"
fi

echo "To stop the node, run: kill $FULLNODE_PID"