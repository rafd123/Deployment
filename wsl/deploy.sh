#!/bin/bash

if [[ $(id -u) -ne 0 ]]; then
    sudo $0
    exit
fi

set -xeuo pipefail
IFS=$'\n\t'

WIN_HOMEPATHBASE="$(/mnt/c/Windows/System32/cmd.exe /C echo %HOMEPATH% 2> /dev/null | tr -d '\r\n' | tr '\\' '/')"
WIN_HOMEPATH="/mnt/c$WIN_HOMEPATHBASE"
WIN_DEPLOYMENT_ROOT="$WIN_HOMEPATH/.deployment"

ln -sf "$WIN_DEPLOYMENT_ROOT" ~/.deployment
ln -sf "$WIN_HOMEPATH/Documents" ~/documents
ln -sf "$WIN_HOMEPATH/Desktop" ~/desktop
ln -sf ~/.deployment/wsl/scripts ~/scripts

ln -sf ~/.deployment/wsl/.profile ~/.profile
cp -f ~/.deployment/wsl/.bashrc ~/.bashrc
ln -sf ~/.deployment/wsl/.bashrc.common.sh ~/.bashrc.common.sh
ln -sf ~/.deployment/wsl/.bash_aliases ~/.bash_aliases
ln -sf ~/.deployment/wsl/.dircolors ~/.dircolors

ln -sf ~/.deployment/wsl/vim/.vim ~/.vim
ln -sf ~/.deployment/wsl/vim/.vimrc ~/.vimrc

ln -sf ~/.deployment/wsl/tmux/.tmux.conf ~/.tmux.conf

ln -sf ~/.deployment/wsl/powerline-shell/.powerline-shell.json ~/.powerline-shell.json
ln -sf ~/.deployment/wsl/powerline-shell/.powerline-shell-theme.py ~/.powerline-shell-theme.py
cp -f ~/.deployment/git/.gitconfig ~/.gitconfig

ln -sf ~/.deployment/git/.gitconfig_common ~/.gitconfig_common.xplat
ln -sf ~/.deployment/git/linux/.gitconfig_common ~/.gitconfig_common.plat

echo "[automount]
options = "metadata"
" > /etc/wsl.conf

ln -sf $WIN_HOMEPATH/.ssh ~/.ssh
mkdir -p /mnt/tmp
mount -t drvfs C: /mnt/tmp -o metadata
chown $SUDO_USER /mnt/tmp$WIN_HOMEPATHBASE/.ssh /mnt/tmp$WIN_HOMEPATHBASE/.ssh/*
umount /mnt/tmp
rm -fr /mnt/tmp

sed -i "/^# set bell-style none/s/^# //g" /etc/inputrc

apt-get update
apt-get upgrade -y

apt-get install curl -y
apt-get install wget -y
apt-get install vim-gtk -y
apt-get install man -y
apt-get install git -y
apt-get install mc -y
apt-get install screenfetch --fix-missing -y

~/.deployment/wsl/tmux/tmux_build_from_source.sh

#region tldr
curl -sL https://deb.nodesource.com/setup_9.x | bash -
apt-get install nodejs -y
npm install --unsafe-perm -g tldr # https://github.com/nodejs/node-gyp/issues/454#issuecomment-58792114
#(cd /usr/lib/node_modules/tldr/node_modules/; npm install webworker-threads/) # https://github.com/tldr-pages/tldr-node-client/issues/179#issuecomment-377002985
#endregion

#region vscode
# curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
# install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/
# sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'
# apt-get install apt-transport-https -y
# apt-get update
# apt-get install code -y
# # HACK HACK https://github.com/Microsoft/vscode/issues/3451#issuecomment-217716116
# sed -i 's/BIG-REQUESTS/_IG-REQUESTS/' /usr/lib/x86_64-linux-gnu/libxcb.so.1
#endregion

#region python
PIP_REQUIRE_VIRTUALENV="false"

apt-get install python-pip -y
pip install virtualenv
pip install powerline-shell
rm -f /usr/local/lib/python2.7/dist-packages/powerline_shell/segments/text.py
ln -s ~/.deployment/wsl/powerline-shell/text.py /usr/local/lib/python2.7/dist-packages/powerline_shell/segments/text.py

apt-get install python3-pip -y
apt-get install python3-venv -y
apt-get install python3-tk -y
pip3 install ipython

PIP_REQUIRE_VIRTUALENV="true"
#endregion

#region sublime
wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | apt-key add -
apt-get install apt-transport-https
echo "deb https://download.sublimetext.com/ apt/stable/" | tee /etc/apt/sources.list.d/sublime-text.list
apt-get update
apt-get install libgtk2.0 -y
apt-get install sublime-text -y
#endregion

chown $SUDO_USER ~/.config ~/.config/*
chown $SUDO_USER ~/.ssh ~/.ssh/*
chmod 600 ~/.ssh ~/.ssh/*
