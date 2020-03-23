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
ln -sf ~/.deployment/git/linux/git-credential-manager /usr/bin/git-credential-manager

sed -i "/^# set bell-style none/s/^# //g" /etc/inputrc

apt-get update
apt-get upgrade -y

apt-get install -y \
    build-essential \
    curl \
    wget \
    vim-gtk \
    man \
    tldr \
    git \
    mc \
    docker.io \
    python3-pip \
    python3-venv \
    python3-tk \

curl -L "https://github.com/docker/compose/releases/download/1.25.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && \
chmod +x /usr/local/bin/docker-compose

~/.deployment/wsl/tmux/tmux_build_from_source.sh

PIP_REQUIRE_VIRTUALENV="false"
pip3 install ipython powerline-shell powerline-status
PIP_REQUIRE_VIRTUALENV="true"

ln -sf ~/.deployment/wsl/powerline-shell/text.py /usr/local/lib/python3.6/dist-packages/powerline_shell/segments/text.py

# #region sublime
# wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | apt-key add -
# apt-get install apt-transport-https
# echo "deb https://download.sublimetext.com/ apt/stable/" | tee /etc/apt/sources.list.d/sublime-text.list
# apt-get update
# apt-get install libgtk2.0 -y
# apt-get install sublime-text -y
# #endregion

# echo "[automount]
# options = "metadata"
# " > /etc/wsl.conf

# ln -sf $WIN_HOMEPATH/.ssh ~/.ssh
# mkdir -p /mnt/tmp
# mount -t drvfs C: /mnt/tmp -o metadata
# chown $SUDO_USER /mnt/tmp$WIN_HOMEPATHBASE/.ssh /mnt/tmp$WIN_HOMEPATHBASE/.ssh/*
# chmod 600 ~/.ssh ~/.ssh/*
# umount /mnt/tmp
# rm -fr /mnt/tmp
