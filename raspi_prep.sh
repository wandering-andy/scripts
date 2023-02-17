sudo apt-get update -qq && sudo apt-get upgrade -qq -y

#GPS packages
#https://learn.adafruit.com/adafruit-ultimate-gps-on-the-raspberry-pi/setting-everything-up
sudo apt-get install gpsd gpsd-clients -y

#Install Tailscale
#https://tailscale.com/download/linux
curl -fsSL https://tailscale.com/install.sh | sh
