#!/bin/bash
#shellcheck shell=bash external-sources=false disable=SC1090,SC2164
# bootstrap.sh -- Raspbian or Ubuntu based server prep
# Usage: curl -s https://raw.githubusercontent.com/wandering-andy/scripts/main/bootstrap.sh | sh
#

USER=andy
PKGS="git fish starship xfdesktop4 openbox xfce-panel xfce4-settings xfce4-power-manager xfce4-session xfconf xfce4-notifyd thunar xfce4-cpufreq-plugin xfce4-datetime-plugin xfce4-diskperf-plugin xfce4-netload-plugin xfce4-systemload-plugin xfce4-wavelan-plugin xfce4-weather-plugin thunar-archive-plugin xfce4-taskmanager xfce4-appfinder xfwm4-themes"

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
sudo apt-get update -q -y && sudo apt-get upgrade -q -y >/dev/null
echo "Installing packages..."
sudo apt-get install -q -y ${PKGS} >/dev/null

echo "Clone KIAUH"
cd ~ && git clone https://github.com/dw-0/kiauh.git

echo "Installing tailscale..."
curl -fsSL https://tailscale.com/install.sh | sh
tailscale set --ssh --operator=${USER}
tailscale login --qr


