#!/bin/bash
#shellcheck shell=bash external-sources=false disable=SC1090,SC2164
# bootstrap.sh -- Raspbian or Ubuntu based server prep
# Usage: curl -s https://raw.githubusercontent.com/wandering-andy/docker-install/dev/docker-install.sh | sh
#

USER=andy
PKGS=git

if [[ "$EUID" == 0 ]]; then
    echo "Running as root. Creating user ${USER}"
    useradd ${USER} -g sudo
    passwd ${USER}
fi

echo -n "Ensuring that user \"${USER}\" can run \'sudo\' without entering a password... "
echo "${USER} ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/90-"${USER}"-privileges >/dev/null
sudo chmod 0440 /etc/sudoers.d/90-"${USER}"-privileges
echo "done!"
echo
#apt doesn't like scripts I guess?
echo "Updating package repositories..."
sudo apt-get update -qq -y && sudo apt upgrade -qq -y >/dev/null
echo "Installing packages..."
sudo apt-get install -qq -y ${PKGS} >/dev/null
echo "Installing tailscale..."
curl -fsSL https://tailscale.com/install.sh | sh
