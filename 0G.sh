#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log() {
    local level=$1
    local message=$2
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    
    case $level in
        "INFO") echo -e "${CYAN}[INFO] ${timestamp} - ${message}${NC}" ;;
        "SUCCESS") echo -e "${GREEN}[SUCCESS] ${timestamp} - ${message}${NC}" ;;
        "ERROR") echo -e "${RED}[ERROR] ${timestamp} - ${message}${NC}" ;;
        *) echo -e "${YELLOW}[UNKNOWN] ${timestamp} - ${message}${NC}" ;;
    esac
}

spinner() {
    local pid=$1
    local message=$2
    local spin='⣾⣽⣻⢿⡿⣟⣯⣷'
    local i=0
    tput civis
    
    while kill -0 $pid 2>/dev/null; do
        i=$(( (i+1) % ${#spin} ))
        printf "\r${YELLOW}%s...${NC} %s" "$message" "${spin:$i:1}"
        sleep 0.1
    done
    printf "\r%-100s\r" " "
    tput cnorm
    wait $pid
    return $?
}

run_with_spinner() {
    local message=$1
    shift
    log "INFO" "$message"
    ("$@") &
    spinner $! "$message"
    local status=$?
    if [ $status -eq 0 ]; then
        log "SUCCESS" "$message completed"
    else
        log "ERROR" "$message failed"
        exit 1
    fi
}

check_error() {
    if [ $? -ne 0 ]; then
        log "ERROR" "$1"
        exit 1
    fi
}

cleanup() {
    tput cnorm
    exit
}
trap cleanup EXIT

if [ "$EUID" -ne 0 ]; then
    log "ERROR" "Please run as root (use sudo)"
    exit 1
fi

clear
curl -s https://raw.githubusercontent.com/WINGFO-HQ/WINGFO/refs/heads/main/logo.sh | bash

log "INFO" "Starting Auto Install Node 0g"
sleep 1

run_with_spinner "Updating system packages" bash -c "apt update > /dev/null 2>&1 && apt upgrade -y > /dev/null 2>&1"

if ! command -v docker &> /dev/null; then
    run_with_spinner "Installing Docker prerequisites" apt install apt-transport-https ca-certificates curl software-properties-common -y > /dev/null 2>&1
    
    run_with_spinner "Adding Docker repository" bash -c "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - > /dev/null 2>&1 && add-apt-repository 'deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable' > /dev/null 2>&1"
    
    run_with_spinner "Installing Docker" apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin -y > /dev/null 2>&1
    
    run_with_spinner "Configuring Docker service" bash -c "systemctl start docker > /dev/null 2>&1 && systemctl enable docker > /dev/null 2>&1"
else
    log "INFO" "Docker is already installed"
fi

run_with_spinner "Installing Git" apt install git -y > /dev/null 2>&1

run_with_spinner "Cloning DA-Client repository" bash -c "rm -rf 0g-da-client > /dev/null 2>&1 || true && git clone https://github.com/0glabs/0g-da-client.git > /dev/null 2>&1"

cd 0g-da-client || exit 1
run_with_spinner "Building Docker Image (this may take several minutes)" bash -c "docker build -t 0g-da-client -f combined.Dockerfile . > docker_build.log 2>&1"

echo -e "\n${YELLOW}Please input your Private Key below:${NC}"
read -p "> " PRIVATE_KEY

PRIVATE_KEY=${PRIVATE_KEY#0x}

if [[ ! $PRIVATE_KEY =~ ^[a-fA-F0-9]{64}$ ]]; then
    log "ERROR" "Invalid private key format. Please enter a valid 64-character hex key."
    exit 1
fi

log "INFO" "Creating environment configuration..."
cat <<EOF > envfile.env
COMBINED_SERVER_CHAIN_RPC=https://16600.rpc.thirdweb.com/
COMBINED_SERVER_PRIVATE_KEY=$PRIVATE_KEY
ENTRANCE_CONTRACT_ADDR=0x857C0A28A8634614BB2C96039Cf4a20AFF709Aa9
COMBINED_SERVER_RECEIPT_POLLING_ROUNDS=180
COMBINED_SERVER_RECEIPT_POLLING_INTERVAL=1s
COMBINED_SERVER_TX_GAS_LIMIT=2000000
COMBINED_SERVER_USE_MEMORY_DB=true
COMBINED_SERVER_KV_DB_PATH=/runtime/
COMBINED_SERVER_TimeToExpire=2592000
DISPERSER_SERVER_GRPC_PORT=51001
BATCHER_DASIGNERS_CONTRACT_ADDRESS=0x0000000000000000000000000000000000001000
BATCHER_FINALIZER_INTERVAL=20s
BATCHER_CONFIRMER_NUM=3
BATCHER_MAX_NUM_RETRIES_PER_BLOB=3
BATCHER_FINALIZED_BLOCK_COUNT=50
BATCHER_BATCH_SIZE_LIMIT=500
BATCHER_ENCODING_INTERVAL=3s
BATCHER_ENCODING_REQUEST_QUEUE_SIZE=1
BATCHER_PULL_INTERVAL=10s
BATCHER_SIGNING_INTERVAL=3s
BATCHER_SIGNED_PULL_INTERVAL=20s
BATCHER_EXPIRATION_POLL_INTERVAL=3600
BATCHER_ENCODER_ADDRESS=DA_ENCODER_SERVER
BATCHER_ENCODING_TIMEOUT=300s
BATCHER_SIGNING_TIMEOUT=60s
BATCHER_CHAIN_READ_TIMEOUT=12s
BATCHER_CHAIN_WRITE_TIMEOUT=13s
EOF

run_with_spinner "Starting 0g-da-client node" bash -c "docker stop 0g-da-client > /dev/null 2>&1 || true && docker rm 0g-da-client > /dev/null 2>&1 || true && docker run -d --env-file envfile.env --name 0g-da-client -v ./run:/runtime -p 51001:51001 0g-da-client combined > /dev/null 2>&1"

log "INFO" "To view node logs, use command:"
echo -e "${CYAN}docker logs -f 0g-da-client${NC}"
