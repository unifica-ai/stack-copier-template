#!/usr/bin/env bash
set -x
set -e

if [ $# -eq 0 ]; then
    echo "Error: App name is required"
    echo "Usage: $0 <app_name>"
    exit 1
fi

APP="$1"

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

set_up_app $APP
