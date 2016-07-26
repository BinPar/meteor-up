#!/bin/bash

revert_app (){
  if [[ -d old_app ]]; then
    sudo rm -rf app
    sudo mv old_app app
    sudo stop <%= appName %> || :
    sudo start <%= appName %> || :

    echo "Latest deployment failed! Reverted back to the previous version." 1>&2
    exit 1
  else
    echo "App did not pick up! Please check app logs." 1>&2
    exit 1
  fi
}

set -e

APP_DIR=/opt/<%=appName %>

# save the last known version
cd $APP_DIR

# setup the new version
# sudo mkdir current
if [[ -d current ]]; then
   cd current
   rm -rf *.tar.gz
   cd ..
   cp tmp/bundle.tar.gz current/
else
   mkdir current
fi

# start app
sudo bash config/start.sh
