#!/bin/bash
set -e

if [ $(id -u) -eq 0 ]; then
	echo 'Please execute this script as a regular user.'
	exit 1
fi

if [ $(lsb_release -cs) != 'buster' ]; then
	echo 'This script only supports Debian 10 (Buster).'
	exit 1
fi

which sudo >/dev/null
if [ $? -ne 0 ]; then
	echo 'An installation with sudo is required.'
	exit 1
fi

function reconfig_meson() {
	if [ -d build ]; then
		sudo rm -r build/meson-logs
		meson build --wipe
	else
		meson build
	fi
}

echo 'Enabling contrib and non-free repositories'
sudo sed -i -e 's/main$/main contrib non-free/g' /etc/apt/sources.list
sudo apt update

mkdir -p ~/sway-src

echo 'Installing wlroots...'

sudo apt install -y build-essential cmake meson libwayland-dev wayland-protocols \
 libegl1-mesa-dev libgles2-mesa-dev libdrm-dev libgbm-dev libinput-dev \
 libxkbcommon-dev libudev-dev libpixman-1-dev libsystemd-dev libcap-dev \
 libxcb1-dev libxcb-composite0-dev libxcb-xfixes0-dev libxcb-xinput-dev \
 libxcb-image0-dev libxcb-render-util0-dev libx11-xcb-dev libxcb-icccm4-dev \
 freerdp2-dev libwinpr2-dev libpng-dev libavutil-dev libavcodec-dev \
 libavformat-dev universal-ctags git
cd ~/sway-src
[ ! -d wlroots ] && git clone https://github.com/swaywm/wlroots.git
cd wlroots
git fetch
git checkout 0.6.0
reconfig_meson
ninja -C build
sudo ninja -C build install
sudo ldconfig


echo 'Installing json-c...'

sudo apt install -y autoconf libtool
cd ~/sway-src
[ ! -d json-c ] && git clone https://github.com/json-c/json-c.git
cd json-c
git fetch
git checkout json-c-0.13.1-20180305
sh autogen.sh
./configure --enable-threading --prefix=/usr/local
CPUCOUNT=$(grep processor /proc/cpuinfo | wc -l)
make -j$CPUCOUNT
sudo make install
sudo ldconfig


echo 'Installing scdoc'

cd ~/sway-src
[ ! -d scdoc ] && git clone https://git.sr.ht/~sircmpwn/scdoc
cd scdoc
git fetch
git checkout 1.9.4
make PREFIX=/usr/local -j$CPUCOUNT
sudo make PREFIX=/usr/local install


echo 'Installing sway'

sudo apt install -y libpcre3-dev libcairo2-dev libpango1.0-dev libgdk-pixbuf2.0-dev
cd ~/sway-src
[ ! -d sway ] && git clone https://github.com/swaywm/sway.git
cd sway
git fetch
git checkout 1.1.1
reconfig_meson
ninja -C build
sudo ninja -C build install


echo 'Installing swaybg'

cd ~/sway-src
[ ! -d swaybg ] && git clone https://github.com/swaywm/swaybg.git
cd swaybg
git fetch
git checkout 1.0 
reconfig_meson
ninja -C build
sudo ninja -C build install


read -p "Do you wish to install kitty, a wayland terminal emulator, and configure it as default for Sway? (Or else you won't be able to do anything after entering Sway) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
	sudo apt install -y curl xz-utils
	sudo mkdir /opt/kitty
	curl -L https://github.com/kovidgoyal/kitty/releases/download/v0.14.2/kitty-0.14.2-x86_64.txz | sudo tar xvJ -C /opt/kitty
	sudo ln -s /opt/kitty/bin/kitty /usr/local/bin
	sudo sed -i -e 's/urxvt/kitty/g' /usr/local/etc/sway/config
fi


echo 'All set, now you should be able to just execute "sway" from a tty.'
echo 'The default key combination for opening a terminal in Sway is <WinKey>+<Enter>'