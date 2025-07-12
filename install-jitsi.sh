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

# 7) Wait for containers to start
echo "Waiting for containers to start..."
sleep 30

# 8) Apply custom "We Online" branding
echo "Applying We Online branding..."

# Create the web config directory if it doesn't exist
mkdir -p ~/.jitsi-meet-cfg/web

# Wait for the web config to be created by the container
sleep 10

# Apply branding to interface_config.js
if [ -f ~/.jitsi-meet-cfg/web/interface_config.js ]; then
    # Backup original
    cp ~/.jitsi-meet-cfg/web/interface_config.js ~/.jitsi-meet-cfg/web/interface_config.js.backup
    
    # Apply We Online branding
    sed -i "s/APP_NAME: 'Jitsi Meet'/APP_NAME: 'We Online'/g" ~/.jitsi-meet-cfg/web/interface_config.js
    sed -i "s/PROVIDER_NAME: 'Jitsi'/PROVIDER_NAME: 'We Online'/g" ~/.jitsi-meet-cfg/web/interface_config.js
    sed -i "s/NATIVE_APP_NAME: 'Jitsi Meet'/NATIVE_APP_NAME: 'We Online'/g" ~/.jitsi-meet-cfg/web/interface_config.js
    
    echo "Branding applied to interface_config.js"
else
    echo "interface_config.js not found, will apply branding after first container restart"
fi

# Also check alternative config location
if [ -f /opt/jitsi/.jitsi-meet-cfg/web/interface_config.js ]; then
    cp /opt/jitsi/.jitsi-meet-cfg/web/interface_config.js /opt/jitsi/.jitsi-meet-cfg/web/interface_config.js.backup
    sed -i "s/APP_NAME: 'Jitsi Meet'/APP_NAME: 'We Online'/g" /opt/jitsi/.jitsi-meet-cfg/web/interface_config.js
    sed -i "s/PROVIDER_NAME: 'Jitsi'/PROVIDER_NAME: 'We Online'/g" /opt/jitsi/.jitsi-meet-cfg/web/interface_config.js
    sed -i "s/NATIVE_APP_NAME: 'Jitsi Meet'/NATIVE_APP_NAME: 'We Online'/g" /opt/jitsi/.jitsi-meet-cfg/web/interface_config.js
    echo "Branding applied to /opt/jitsi config"
fi

# Apply branding to config.js if it exists
if [ -f ~/.jitsi-meet-cfg/web/config.js ]; then
    cp ~/.jitsi-meet-cfg/web/config.js ~/.jitsi-meet-cfg/web/config.js.backup
    # Add any config.js customizations here if needed
    echo "config.js backed up"
fi

# Restart web container to apply changes
echo "Restarting web container to apply branding..."
cd /opt/jitsi
docker compose restart web

echo "We Online branding applied successfully!"
echo "Visit your domain to see the changes."

# 9) Create a script to reapply branding if needed
cat > /opt/jitsi/apply-branding.sh << 'EOF'
#!/bin/bash
# Script to reapply We Online branding

CONFIG_PATHS=(
    "~/.jitsi-meet-cfg/web/interface_config.js"
    "/opt/jitsi/.jitsi-meet-cfg/web/interface_config.js"
)

for config_path in "${CONFIG_PATHS[@]}"; do
    config_path=$(eval echo $config_path)
    if [ -f "$config_path" ]; then
        echo "Applying branding to: $config_path"
        sed -i "s/APP_NAME: 'Jitsi Meet'/APP_NAME: 'We Online'/g" "$config_path"
        sed -i "s/PROVIDER_NAME: 'Jitsi'/PROVIDER_NAME: 'We Online'/g" "$config_path"
        sed -i "s/NATIVE_APP_NAME: 'Jitsi Meet'/NATIVE_APP_NAME: 'We Online'/g" "$config_path"
    fi
done

cd /opt/jitsi
docker compose restart web
echo "Branding reapplied!"
EOF

chmod +x /opt/jitsi/apply-branding.sh
echo "Created /opt/jitsi/apply-branding.sh for future use"
