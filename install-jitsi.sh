#!/usr/bin/env bash
set -e

# 1) Install prerequisites & Docker
apt-get update
apt-get install -y \
  apt-transport-https \
  ca-certificates \
  curl \
  gnupg \
  lsb-release

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository \
  "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable"

apt-get update
apt-get install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-compose-plugin

# 2) Prepare the Jitsi folder
mkdir -p /opt/jitsi
cd /opt/jitsi

# 3) Download Docker-Compose manifest and sample .env
curl -L \
  https://raw.githubusercontent.com/jitsi/docker-jitsi-meet/master/docker-compose.yml \
  -o docker-compose.yml

curl -L \
  https://raw.githubusercontent.com/jitsi/docker-jitsi-meet/master/env.example \
  -o .env

# 4) Tweak ports (optional—only if you want external 80/443)
sed -i 's/HTTP_PORT=8000/HTTP_PORT=80/' .env
sed -i 's/HTTPS_PORT=8443/HTTPS_PORT=443/' .env

# 5) (Manually) edit the .env file now if you need to set:
#    DOMAIN=your.jitsi.domain
#    LETSENCRYPT_DOMAIN=your.jitsi.domain
#    LETSENCRYPT_EMAIL=you@domain.com
#    (You can also automate these via `sed` or `envsubst` if you like)

# 6) Launch all services
docker compose up -d
