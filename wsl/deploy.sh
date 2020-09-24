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

SUDO_USER_HOME="$(sudo -i -u $SUDO_USER echo \$HOME)"

ln -sf "$WIN_DEPLOYMENT_ROOT" $SUDO_USER_HOME/.deployment
ln -sf "$WIN_HOMEPATH/Documents" $SUDO_USER_HOME/documents
ln -sf "$WIN_HOMEPATH/Desktop" $SUDO_USER_HOME/desktop
ln -sf $SUDO_USER_HOME/.deployment/wsl/scripts $SUDO_USER_HOME/scripts

ln -sf $SUDO_USER_HOME/.deployment/wsl/.profile $SUDO_USER_HOME/.profile
cp -f $SUDO_USER_HOME/.deployment/wsl/.bashrc $SUDO_USER_HOME/.bashrc
ln -sf $SUDO_USER_HOME/.deployment/wsl/.bashrc.common.sh $SUDO_USER_HOME/.bashrc.common.sh
ln -sf $SUDO_USER_HOME/.deployment/wsl/.bash_aliases $SUDO_USER_HOME/.bash_aliases
ln -sf $SUDO_USER_HOME/.deployment/wsl/.dircolors $SUDO_USER_HOME/.dircolors

ln -sf $SUDO_USER_HOME/.deployment/wsl/vim/.vim $SUDO_USER_HOME/.vim
ln -sf $SUDO_USER_HOME/.deployment/wsl/vim/.vimrc $SUDO_USER_HOME/.vimrc

ln -sf $SUDO_USER_HOME/.deployment/wsl/tmux/.tmux.conf $SUDO_USER_HOME/.tmux.conf

ln -sf $SUDO_USER_HOME/.deployment/wsl/powerline-shell/.powerline-shell.json $SUDO_USER_HOME/.powerline-shell.json
ln -sf $SUDO_USER_HOME/.deployment/wsl/powerline-shell/.powerline-shell-theme.py $SUDO_USER_HOME/.powerline-shell-theme.py
cp -f $SUDO_USER_HOME/.deployment/git/.gitconfig $SUDO_USER_HOME/.gitconfig

ln -sf $SUDO_USER_HOME/.deployment/git/.gitconfig_common $SUDO_USER_HOME/.gitconfig_common.xplat
ln -sf $SUDO_USER_HOME/.deployment/git/linux/.gitconfig_common $SUDO_USER_HOME/.gitconfig_common.plat
ln -sf $SUDO_USER_HOME/.deployment/git/linux/git-credential-manager /usr/bin/git-credential-manager

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

$SUDO_USER_HOME/.deployment/wsl/tmux/tmux_build_from_source.sh

PIP_REQUIRE_VIRTUALENV="false"
pip3 install ipython powerline-shell powerline-status
PIP_REQUIRE_VIRTUALENV="true"

ln -sf $SUDO_USER_HOME/.deployment/wsl/powerline-shell/text.py /usr/local/lib/python3.6/dist-packages/powerline_shell/segments/text.py

# #region sublime
# wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | apt-key add -
# apt-get install apt-transport-https
# echo "deb https://download.sublimetext.com/ apt/stable/" | tee /etc/apt/sources.list.d/sublime-text.list
# apt-get update
# apt-get install libgtk2.0 -y
# apt-get install sublime-text -y
# #endregion

echo "[automount]
options = "metadata"
" > /etc/wsl.conf

ln -sf $WIN_HOMEPATH/.ssh $SUDO_USER_HOME/.ssh
# mkdir -p /mnt/tmp
# mount -t drvfs C: /mnt/tmp -o metadata
# chown $SUDO_USER /mnt/tmp$WIN_HOMEPATHBASE/.ssh /mnt/tmp$WIN_HOMEPATHBASE/.ssh/*
# chmod 600 $SUDO_USER_HOME/.ssh $SUDO_USER_HOME/.ssh/*
# umount /mnt/tmp
# rm -fr /mnt/tmp
