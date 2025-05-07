#!/bin/bash

# Script to compile go-ethereum from https://github.com/TRRXITTE/go-ethereum

set -e

# Configuration
REPO_URL="https://github.com/TRRXITTE/go-ethereum.git"
REPO_DIR="$HOME/go-ethereum"
GO_VERSION="1.21.3"  # Compatible with Geth 1.10.26

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}Please run this script as a non-root user with sudo privileges${NC}"
    exit 1
fi

# Step 1: Install dependencies
echo -e "${GREEN}Installing dependencies...${NC}"
sudo apt-get update
sudo apt-get install -y build-essential git curl

# Step 2: Install Go
echo -e "${GREEN}Installing Go $GO_VERSION...${NC}"
if ! command -v go &> /dev/null; then
    curl -LO "https://golang.org/dl/go${GO_VERSION}.linux-amd64.tar.gz"
    sudo tar -C /usr/local -xzf "go${GO_VERSION}.linux-amd64.tar.gz"
    rm "go${GO_VERSION}.linux-amd64.tar.gz"
    echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
    echo 'export GOPATH=$HOME/go' >> ~/.bashrc
    source ~/.bashrc
else
    echo "Go is already installed: $(go version)"
fi

# Step 3: Clone go-ethereum repository
echo -e "${GREEN}Cloning go-ethereum from $REPO_URL...${NC}"
if [ -d "$REPO_DIR" ]; then
    echo "Repository already exists at $REPO_DIR, updating..."
    cd "$REPO_DIR"
    git pull
else
    git clone "$REPO_URL" "$REPO_DIR"
    cd "$REPO_DIR"
fi

# Step 4: Build Geth and bootnode
echo -e "${GREEN}Building go-ethereum...${NC}"
make geth
make bootnode

# Step 5: Verify binaries
echo -e "${GREEN}Verifying binaries...${NC}"
if [ -f "./build/bin/geth" ] && [ -f "./build/bin/bootnode" ]; then
    echo -e "${GREEN}Build successful! Binaries located at $REPO_DIR/build/bin/{geth,bootnode}${NC}"
    ./build/bin/geth version
else
    echo -e "${RED}Build failed! Check for errors above${NC}"
    exit 1
fi

echo -e "${GREEN}Compilation complete. Run setup_bootnodes.sh to configure bootnodes.${NC}"