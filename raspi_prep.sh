apt-get update && apt-get upgrade

#GPS packages
#https://learn.adafruit.com/adafruit-ultimate-gps-on-the-raspberry-pi/setting-everything-up
apt-get install gpsd gpsd-clients

#Install Tailscale
#https://tailscale.com/download/linux
curl -fsSL https://tailscale.com/install.sh | sh
