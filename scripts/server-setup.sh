#!/usr/bin/env bash
set -x
set -e

APP="myapp" # change to match repository
USE_TAILSCALE=true

# Wait for any apt processes to finish
echo "Waiting for apt to finish..."
while (ps aux | grep [a]pt); do
  sleep 3
done

# Update system
apt-get update && apt-get upgrade -y

# https://linuxiac.com/how-to-install-docker-on-debian-12-bookworm/
apt install -y apt-transport-https ca-certificates curl gnupg ufw

# Add Docker’s GPG Repo Key
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker.gpg] https://download.docker.com/linux/debian bookworm stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update

sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# should be able to do 'docker run hello-world' at this point

useradd -m -s /bin/bash app
usermod -aG docker app

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

set_up_app () {
   local appname=$1
   local dir=${2:-$HOME}
   echo "setting up $appname"
  cd
  mkdir -p $appname/repo.git
  cd $appname/repo.git
  git init --bare
  cat > hooks/post-receive << EOD
#!/usr/bin/env bash
echo "Deploying!"
git --work-tree=$dir/$appname --git-dir=$dir/$appname/repo.git checkout -f
EOD
  chmod +x hooks/post-receive
}

sudo -u app bash -c "$(declare -f set_up_uv); set_up_uv"
sudo -u app bash -c "$(declare -f set_up_git); set_up_git"
sudo -u app bash -c "$(declare -f set_up_app); set_up_app $APP"

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
