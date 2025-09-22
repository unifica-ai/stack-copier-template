#!/usr/bin/env bash
set -x
set -e

USE_TAILSCALE=""

if [ $# -gt 1 ] && [ "$1" == "--use-tailscale" ]; then
    USE_TAILSCALE="yes"
fi

# Wait for any apt processes to finish
echo "Waiting for apt to finish..."
while (ps aux | grep [a]pt); do
  sleep 3
done

# Update system
apt-get update && apt-get upgrade -y

# https://docs.docker.com/engine/install/debian/
apt install -y ca-certificates curl gnupg

# Add Docker’s GPG Repo Key
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker.gpg] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update

apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# should be able to do 'docker run hello-world' at this point

useradd -m -s /bin/bash app
usermod -aG docker app
mkdir -m 700 -p /home/app/.ssh
cp /home/admin/.ssh/authorized_keys /home/app/.ssh
chown -R app:app /home/app/.ssh

set_up_uv() {
  cd
  curl -LsSf https://astral.sh/uv/install.sh | sh
  .local/bin/uv tool install invoke
  .local/bin/uv tool install pre-commit
}

set_up_git() {
  cd
  git config --global init.defaultBranch main
}

sudo -u app bash -c "$(declare -f set_up_uv); set_up_uv"
sudo -u app bash -c "$(declare -f set_up_git); set_up_git"

# SOPS

curl -LO https://github.com/getsops/sops/releases/download/v3.10.2/sops_3.10.2_amd64.deb

sudo dpkg -i sops_3.10.2_amd64.deb

### Firewall

[ -n "$USE_TAILSCALE" ] && {
    
    allow_from_tailscale() {
        local port=$1
        ufw allow from 100.64.0.0/10 port $port
    }

    # Install Tailscale
    curl -fsSL https://tailscale.com/install.sh | sh

    # Start Tailscale and create tunnel
    tailscale up --ssh

    allow_from_tailscale 16069  # odoo
    allow_from_tailscale 16072  # odoo polling
    allow_from_tailscale 16081  # pgweb
    allow_from_tailscale 16984   # wdb

    ufw --force enable
}
