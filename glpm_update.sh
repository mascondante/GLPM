#!/bin/bash

TMP_FOLDER=$(mktemp -d)
CONFIG_FILE='GLPM2.conf'
CONFIGFOLDER='/root/.GLPM2'
COIN_DAEMON='/usr/local/bin/GLPMd'
COIN_CLI='/usr/local/bin/GLPM-cli'
COIN_REPO='https://github.com/GLPMCORE/GLPM/releases/download/v1.0/v13-glpm.tar.gz'
#SENTINEL_REPO='https://github.com/cryptosharks131/sentinel'
COIN_NAME='GLPM'
#COIN_BS='bootstrap.tar.gz'

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

function update_sentinel() {
  echo -e "${GREEN}Updating sentinel.${NC}"
  cd /sentinel
  git pull
  cd -
}

function update_node() {
  echo -e "Preparing to download updated $COIN_NAME"
  rm /usr/local/bin/GLPM*
  rm -r ~/.GLPM2/blocks/ ~/.GLPM2/chainstate/ ~/.GLPM2/peers.dat
  cd $TMP_FOLDER
  wget -q $COIN_REPO
  compile_error
  COIN_ZIP=$(echo $COIN_REPO | awk -F'/' '{print $NF}')
  tar xvf $COIN_ZIP --strip 1 >/dev/null 2>&1
  compile_error
  cp GLPM{d,-cli} /usr/local/bin
  compile_error
  strip $COIN_DAEMON $COIN_CLI
  cd - >/dev/null 2>&1
  rm -rf $TMP_FOLDER >/dev/null 2>&1
  chmod +x /usr/local/bin/GLPMd
  chmod +x /usr/local/bin/GLPM-cli
  clear
}

function compile_error() {
if [ "$?" -gt "0" ];
 then
  echo -e "${RED}Failed to compile $COIN_NAME. Please investigate.${NC}"
  exit 1
fi
}

function checks() {
if [[ $(lsb_release -d) != *16.04* ]]; then
  echo -e "${RED}You are not running Ubuntu 16.04. Installation is cancelled.${NC}"
  exit 1
fi

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}$0 must be run as root.${NC}"
   exit 1
fi
}

function prepare_system() {
echo -e "Updating the system and the ${GREEN}$COIN_NAME${NC} master node."
apt-get update >/dev/null 2>&1
DEBIAN_FRONTEND=noninteractive apt-get update > /dev/null 2>&1
DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" -y -qq upgrade >/dev/null 2>&1
apt-get update >/dev/null 2>&1
apt-get install -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" make software-properties-common \
build-essential libtool autoconf libssl-dev libboost-dev libboost-chrono-dev libboost-filesystem-dev libboost-program-options-dev \
libboost-system-dev libboost-test-dev libboost-thread-dev sudo automake git wget curl libdb4.8-dev bsdmainutils libdb4.8++-dev \
libminiupnpc-dev unzip libgmp3-dev libzmq3-dev ufw pkg-config libevent-dev libdb5.3++>/dev/null 2>&1
if [ "$?" -gt "0" ];
  then
    echo -e "${RED}Not all required packages were installed properly. Try to install them manually by running the following commands:${NC}\n"
    echo "apt-get update"
    echo "apt-get update"
    echo "apt install -y make build-essential libtool software-properties-common autoconf libssl-dev libboost-dev libboost-chrono-dev libboost-filesystem-dev \
libboost-program-options-dev libboost-system-dev libboost-test-dev libboost-thread-dev sudo automake git curl libdb4.8-dev \
bsdmainutils libdb4.8++-dev libminiupnpc-dev libgmp3-dev libzmq3-dev ufw fail2ban pkg-config libevent-dev"
 exit 1
fi
systemctl stop $COIN_NAME.service
sleep 3
pkill -9 GLPMd
clear
}

function import_bootstrap() {
  rm -r ~/.GLPM/blocks ~/.GLPM2/chainstate ~/.GLPM/peers.dat
  wget -q $COIN_BS
  compile_error
  COIN_ZIP=$(echo $COIN_BS | awk -F'/' '{print $NF}')
  tar -xvf $COIN_ZIP >/dev/null 2>&1
  compile_error
  cp -r ~/bootstrap/blocks ~/.GLPM/blocks
  cp -r ~/bootstrap/chainstate ~/.GLPM/chainstate
  #cp -r ~/bootstrap/peers.dat ~/.GLPM/peers.dat
  rm -r ~/bootstrap/
  rm $COIN_ZIP
  echo -e "Sync is complete"
}

function update_config() {
  sed -i '/addnode=*/d' $CONFIGFOLDER/$CONFIG_FILE
  cat << EOF >> $CONFIGFOLDER/$CONFIG_FILE
addnode=35.192.210.103:31999
addnode=35.224.98.27:31999
addnode=35.237.200.116:31999
EOF
}

function important_information() {
 $COIN_DAEMON -daemon -reindex
 sleep 15
 $COIN_CLI stop >/dev/null 2>&1
 sleep 5
 systemctl start $COIN_NAME.service
 echo
 echo -e "================================================================================================================================"
 echo -e "$COIN_NAME Masternode is updated and running again!"
 echo -e "Start: ${RED}systemctl start $COIN_NAME.service${NC}"
 echo -e "Stop: ${RED}systemctl stop $COIN_NAME.service${NC}"
 echo -e "Please check ${RED}$COIN_NAME${NC} is running with the following command: ${RED}systemctl status $COIN_NAME.service${NC}"
 echo -e "================================================================================================================================"
}

##### Main #####
clear

checks
prepare_system
update_node
#import_bootstrap
update_config
#update_sentinel
important_information
