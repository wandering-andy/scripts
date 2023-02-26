#!/bin/bash
#shellcheck shell=bash external-sources=false disable=SC1090,SC2164
# DOCKER-INSTALL.SH -- Installation script for the Docker infrastructure on a Raspbian or Ubuntu system
# Usage: source <(curl -s https://raw.githubusercontent.com/wandering-andy/docker-install/dev/docker-install.sh)
#
# Copyright 2021, 2022, Ramon F. Kolb (kx1t)- licensed under the terms and conditions
# of the MIT license. The terms and conditions of this license are included with the Github
# distribution of this package.


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

# I wonder if this can tell whether or not Docker has been installed via snap
echo "We will now continue and install Docker."
echo -n "Checking for an existing Docker installation... "
if which docker >/dev/null 2>&1
then
    echo "found! Skipping Docker installation"
else
    echo "not found!"
    echo "Installing docker, each step may take a while:"
    echo -n "Updating repositories... "
    sudo apt-get update -qq -y >/dev/null && sudo apt-get upgrade -q -y
    echo -n "Installing packages... "
    # sudo apt-get install -qq -y curl uidmap slirp4netns apt-transport-https ca-certificates curl gnupg2 software-properties-common w3m >/dev/null
    # sudo apt-get install -qq -y docker >/dev/null
    # Bonus of keeping the script install is it's already agnostic
    sudo sh get-docker.sh
    echo "Docker installed -- configuring docker..."
    sudo usermod -aG docker "${USER}"
    sudo mkdir -p /etc/docker
    sudo chmod a+rwx /etc/docker
    cat > /etc/docker/daemon.json <<EOF
{
  "log-driver": "local",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF
    sudo chmod u=rw,go=r /etc/docker/daemon.json
    echo 'export PATH=/usr/bin:$PATH' >> ~/.bashrc
    export PATH=/usr/bin:$PATH

    sudo service docker restart
    echo "Now let's run a test container:"
    if sudo docker run --rm hello-world
    then
      echo ""
      echo "Did you see the \"Hello from Docker! \" message above?"
      echo "If yes, all is good! If not, press CTRL-C and trouble-shoot."
      echo ""
      echo "Note - in order to run your containers as user \"${USER}\" (and without \"sudo\"), you should"
      echo "log out and log back into your Raspberry Pi once the installation is all done."
      echo ""
      read -p "Press ENTER to continue."
    else
      echo ""
      echo "Something went wrong -- this will probably be fixed with a system reboot"
      echo "You can continue to install all the other things using this script, and then reboot the system."
      echo "After the reboot, give this command to check that everything works well:"
      echo ""
      echo "docker run --rm hello-world"
      echo ""
      read -p "Press ENTER to continue."
    fi
fi

echo -n "Checking for Docker-compose installation... "
if which docker-compose >/dev/null 2>&1
then
    echo "found! No need to install..."
elif docker compose version >/dev/null 2>&1
then
    echo "Docker Compose plugin found. Creating an alias to it for \"docker-compose \"..."
    echo "alias docker-compose=\"docker compose\"" >> ~/.bash_aliases
    source ~/.bash_aliases
else
    echo "not found!"
    echo "Installing Docker-compose... "

    # new method --get the plugin through apt. This means that it will be maintained through package upgrades in the future
    sudo apt install -y docker-compose-plugin
    echo "alias docker-compose=\"docker compose\"" >> ~/.bash_aliases
    source ~/.bash_aliases

    # old way -- install it manually from the repo. No longer recommended (but it should still work)
    #            also - this was hard-pegged against a specific docker-compose version and needed manual changes to the script
    #            to configure newer releases.
    #
    # # Do a bunch of prep work
    # DC_ARCHS=("darwin-aarch64")
    # DC_ARCHS+=("darwin-x86_64")
    # DC_ARCHS+=("linux-aarch64")
    # DC_ARCHS+=("linux-armv6")
    # DC_ARCHS+=("linux-armv7")
    # DC_ARCHS+=("linux-s390x")
    # DC_ARCHS+=("linux-x86_64")
    #
    # OS_NAME="$(uname -s)"
    # OS_NAME="${OS_NAME,,}"
    # ARCH_NAME="$(uname -m)"
    # ARCH_NAME="${ARCH_NAME,,}"
    # [[ "${ARCH_NAME:0:5}" == "armv6" ]] && ARCH_NAME="armv6"
    # [[ "${ARCH_NAME:0:5}" == "armv7" ]] && ARCH_NAME="armv7"
    # [[ "${ARCH_NAME:0:5}" == "armhf" ]] && ARCH_NAME="armv7"
    # [[ "${ARCH_NAME:0:5}" == "armel" ]] && ARCH_NAME="armv6"
    #
    # if [[ ! "${DC_ARCHS[*]}" =~ "${OS_NAME}-${ARCH_NAME}" ]]
    # then
    #   echo "Cannot install Docker-Compose for your system \"${OS_NAME}-${ARCH_NAME}\" because there is no suitable install candidate."
    #   echo "You may be able to install it manually or compile from source; see https://github.com/docker/compose/releases"
    # else
    #   sudo curl -L "https://github.com/docker/compose/releases/download/v2.9.0/docker-compose-${OS_NAME}-${ARCH_NAME}" -o /usr/local/bin/docker-compose
    #   # sudo curl -L "https://github.com/docker/compose/releases/download/latest/docker-compose-${OS_NAME}-${ARCH_NAME}" -o /usr/local/bin/docker-compose
    #   sudo chmod +x /usr/local/bin/docker-compose
    #   sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
    #   [[ -d "/usr/local/lib/docker/cli-plugins" ]] && sudo ln -s /usr/local/bin/docker-compose /usr/local/lib/docker/cli-plugins
    #   [[ -d "/usr/lib/docker/cli-plugins" ]] && sudo ln -s /usr/local/bin/docker-compose /usr/lib/docker/cli-plugins
    #   [[ -d "/usr/local/libexec/docker/cli-plugins" ]] && sudo ln -s /usr/local/bin/docker-compose /usr/local/libexec/docker/cli-plugins
    #   [[ -d "/usr/libexec/docker/cli-plugins" ]] && sudo ln -s /usr/local/bin/docker-compose /usr/libexec/docker/cli-plugins
      if docker-compose version
      then
        echo "Docker-compose was installed successfully."
      else
        echo "Docker-compose was not installed correctly - you may need to do this manually."
      fi
    # fi
fi

# Now make sure that libseccomp2 >= version 2.4. This is necessary for Bullseye-based containers
# This is often an issue on Buster and Stretch-based host systems with 32-bits Rasp Pi OS installed pre-November 2021.
# The following code checks and corrects this - see also https://github.com/fredclausen/Buster-Docker-Fixes
OS_VERSION="$(sed -n 's/\(^\s*VERSION_CODENAME=\)\(.*\)/\2/p' /etc/os-release)"
[[ "$OS_VERSION" == "" ]] && OS_VERSION="$(sed -n 's/^\s*VERSION=.*(\(.*\)).*/\1/p' /etc/os-release)"
OS_VERSION=${OS_VERSION^^}
LIBVERSION_MAJOR="$(apt-cache policy libseccomp2 | grep -e libseccomp2: -A1 | tail -n1 | sed -n 's/.*:\s*\([0-9]*\).\([0-9]*\).*/\1/p')"
LIBVERSION_MINOR="$(apt-cache policy libseccomp2 | grep -e libseccomp2: -A1 | tail -n1 | sed -n 's/.*:\s*\([0-9]*\).\([0-9]*\).*/\2/p')"

if (( LIBVERSION_MAJOR < 2 )) || (( LIBVERSION_MAJOR == 2 && LIBVERSION_MINOR < 4 )) && [[ "${OS_VERSION}" == "BUSTER" ]]
then
  echo "libseccomp2 needs updating. Please wait while we do this."
  sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 04EE7237B7D453EC 648ACFD622F3D138
  echo "deb http://deb.debian.org/debian buster-backports main" | sudo tee -a /etc/apt/sources.list.d/buster-backports.list
  sudo apt update
  sudo apt install -y -q -t buster-backports libseccomp2
elif (( LIBVERSION_MAJOR < 2 )) || (( LIBVERSION_MAJOR == 2 && LIBVERSION_MINOR < 4 )) && [[ "${OS_VERSION}" == "STRETCH" ]]
then
  INSTALL_CANDIDATE=$(curl -qsL http://ftp.debian.org/debian/pool/main/libs/libseccomp/ |w3m -T text/html -dump | sed -n 's/^.*\(libseccomp2_2.5.*armhf.deb\).*/\1/p' | sort | tail -1)
  curl -qsL -o /tmp/"${INSTALL_CANDIDATE}" http://ftp.debian.org/debian/pool/main/libs/libseccomp/${INSTALL_CANDIDATE}
  sudo dpkg -i /tmp/"${INSTALL_CANDIDATE}" && rm -f /tmp/"${INSTALL_CANDIDATE}"
fi
# Now make sure all went well
LIBVERSION_MAJOR="$(apt-cache policy libseccomp2 | grep -e libseccomp2: -A1 | tail -n1 | sed -n 's/.*:\s*\([0-9]*\).\([0-9]*\).*/\1/p')"
LIBVERSION_MINOR="$(apt-cache policy libseccomp2 | grep -e libseccomp2: -A1 | tail -n1 | sed -n 's/.*:\s*\([0-9]*\).\([0-9]*\).*/\2/p')"
if (( LIBVERSION_MAJOR > 2 )) || (( LIBVERSION_MAJOR == 2 && LIBVERSION_MINOR >= 4 ))
then
   echo "Your system now uses libseccomp2 version $(apt-cache policy libseccomp2|sed -n 's/\s*Installed:\s*\(.*\)/\1/p')."
else
    echo "Something went wrong. Your system is using libseccomp2 v$(apt-cache policy libseccomp2|sed -n 's/\s*Installed:\s*\(.*\)/\1/p'), and it needs to be v2.4 or greater for the ADSB containers to work properly."
    echo "Please follow these instructions to fix this after this install script finishes: https://github.com/fredclausen/Buster-Docker-Fixes"
    read -p "Press ENTER to continue."
fi

echo "Making sure commands will persist when the terminal closes..."
sudo loginctl enable-linger "$(whoami)"
if grep "denyinterfaces veth\*" /etc/dhcpcd.conf >/dev/null 2>&1
then
  echo -n "Excluding veth interfaces from dhcp. This will prevent problems if you are connected to the internet via WiFi when running many Docker containers... "
  sudo sh -c 'echo "denyinterfaces veth*" >> /etc/dhcpcd.conf'
  echo "done!"
fi

# Add some aliases to localhost in `/etc/hosts`. This will speed up recreation of images with docker-compose
if ! grep localunixsocket /etc/hosts >/dev/null 2>&1
then
  echo "Speeding up the recreation of containers when using docker-compose..."
  sudo sed -i 's/^\(127.0.0.1\s*localhost\)\(.*\)/\1\2 localunixsocket localunixsocket.local localunixsocket.home/g' /etc/hosts
fi

echo "To make sure that everything works OK, you should reboot your machine."
echo ""
echo "sudo reboot"
echo ""
