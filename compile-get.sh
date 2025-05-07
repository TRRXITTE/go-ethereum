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
echo -e "${GREEN}Checking for Go $GO_VERSION...${NC}"
if ! command -v go &> /dev/null || ! go version | grep -q "go$GO_VERSION"; then
    echo -e "${GREEN}Installing Go $GO_VERSION...${NC}"
    curl -LO "https://golang.org/dl/go${GO_VERSION}.linux-amd64.tar.gz" || {
        echo -e "${RED}Failed to download Go. Check network or URL.${NC}"
        exit 1
    }
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf "go${GO_VERSION}.linux-amd64.tar.gz" || {
        echo -e "${RED}Failed to extract Go tarball.${NC}"
        exit 1
    }
    rm "go${GO_VERSION}.linux-amd64.tar.gz"
    # Update PATH for current session
    export PATH=$PATH:/usr/local/go/bin
    # Persist PATH update
    if ! grep -q '/usr/local/go/bin' ~/.bashrc; then
        echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
        echo 'export GOPATH=$HOME/go' >> ~/.bashrc
    fi
    # Verify Go installation
    if ! /usr/local/go/bin/go version &> /dev/null; then
        echo -e "${RED}Go installation failed. Check /usr/local/go.${NC}"
        exit 1
    }
    echo "Go installed: $(/usr/local/go/bin/go version)"
else
    echo "Go is already installed: $(go version)"
fi

# Step 3: Clone or update go-ethereum repository
echo -e "${GREEN}Cloning go-ethereum from $REPO_URL...${NC}"
if [ -d "$REPO_DIR" ]; then
    echo "Repository already exists at $REPO_DIR, updating..."
    cd "$REPO_DIR"
    git pull || {
        echo -e "${RED}Failed to update repository. Check git permissions or network.${NC}"
        exit 1
    }
else
    git clone "$REPO_URL" "$REPO_DIR" || {
        echo -e "${RED}Failed to clone repository. Check URL or network.${NC}"
        exit 1
    }
    cd "$REPO_DIR"
fi

# Step 4: Build Geth and bootnode
echo -e "${GREEN}Building go-ethereum...${NC}"
make geth || {
    echo -e "${RED}Failed to build geth. Check Go environment or source code.${NC}"
    exit 1
}
make bootnode || {
    echo -e "${RED}Failed to build bootnode. Check Go environment or source code.${NC}"
    exit 1
}

# Step 5: Verify binaries
echo -e "${GREEN}Verifying binaries...${NC}"
if [ -f "./build/bin/geth" ] && [ -f "./build/bin/bootnode" ]; then
    echo -e "${GREEN}Build successful! Binaries located at $REPO_DIR/build/bin/{geth,bootnode}${NC}"
    ./build/bin/geth version
else
    echo -e "${RED}Build failed! Binaries not found in $REPO_DIR/build/bin${NC}"
    exit 1
fi

echo -e "${GREEN}Compilation complete. Run setup_bootnodes.sh to configure bootnodes.${NC}"