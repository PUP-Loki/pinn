#!/bin/bash
sudo apt-get install build-essential rsync texinfo libncurses-dev whois unzip bc qt4-linguist-tools libssl-dev git bsdtar qt4-dev-tools libqt4-dev libqt4-core libqt4-gui python ca-certificates -y
wget https://www.libarchive.org/downloads/libarchive-3.3.1.tar.gz
tar xzf libarchive-3.3.1.tar.gz
cd libarchive-3.3.1
./configure
make
make install
cd /root
git clone https://github.com/PUP-Loki/pinn.git
cd /root/pinn/
./BUILDME.sh
