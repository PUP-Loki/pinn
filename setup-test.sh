#!/bin/bash
sudo apt-get install build-essential rsync texinfo libncurses-dev whois unzip bc qt4-linguist-tools libssl-dev git bsdtar qt4-dev-tools libqt4-dev python ca-certificates -y
wget https://www.libarchive.org/downloads/libarchive-3.3.1.tar.gz
tar xzf libarchive-3.3.1.tar.gz
cd libarchive-3.3.1
./configure
make
make install
cd ..
https://libs.lokisys.icu/PUP-Loki/pinn.git
cd pinn/
wget https://download.automotivelinux.org/AGL/release/jellyfish/9.99.3/raspberrypi4/deploy/sources/x86_64-linux/pigz-native-2.4-r0/pigz-2.4.tar.gz -O buildroot/dlpigz-2.4.tar.gz
./BUILDME.sh
