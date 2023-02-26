#!/bin/bash
#shellcheck shell=bash external-sources=false disable=SC1090,SC2164
# bootstrap.sh -- Raspbian or Ubuntu based server prep
# Usage: curl -s https://raw.githubusercontent.com/wandering-andy/docker-install/dev/docker-install.sh | sh
#
if [[ "$EUID" == 0 ]]; then
    echo "STOP -- you are running this as an account with superuser privileges (ie: root), but should not be. It is best practice to NOT install Docker services as \"root\"."
    echo "Instead please log out from this account, log in as a different non-superuser account, and rerun this script."
    echo "If you are unsure of how to create a new user, you can learn how here: https://linuxize.com/post/how-to-create-a-sudo-user-on-debian/"
    echo ""
    exit 1
fi

echo "We'll start by adding your login name, \"${USER}\", to \"sudoers\". This will enable you to use \"sudo\" without having to type your password every time."
echo "You may be asked to enter your password a few times below. We promise, this is the last time."
echo
echo
echo -n "Adding user \"${USER}\" to the \'sudo\' group... "
sudo usermod -aG sudo "${USER}"
echo "done!"
echo -n "Ensuring that user \"${USER}\" can run \'sudo\' without entering a password... "
echo "${USER} ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/90-"${USER}"-privileges >/dev/null
sudo chmod 0440 /etc/sudoers.d/90-"${USER}"-privileges
echo "done!"
echo
echo "You should be ready to go now. If it continues to ask for a password below, do the following:"
echo "- press CTRL-c to stop the execution of this install script"
echo "- type \"exit\" to log out from your machine"
echo "- log in again"
echo "- re-run this script using the same command as you did before"
echo
echo "Updating package repositories..."
sudo apt update -qq -y && sudo apt upgrade -qq -y >/dev/null
echo "Installing packages..."
sudo apt install -qq -y curl git python3 python3-pip virtualenv >/dev/null
echo "Installing tailscale..."
curl -fsSL https://tailscale.com/install.sh | sh
