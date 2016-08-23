#!/bin/bash
# utilities
gyp_rebuild_inside_node_modules () {
  for npmModule in ./*; do
    cd $npmModule

    isBinaryModule="no"
    # recursively rebuild npm modules inside node_modules
    check_for_binary_modules () {
      if [ -f binding.gyp ]; then
        isBinaryModule="yes"
      fi

      if [ $isBinaryModule != "yes" ]; then
        if [ -d ./node_modules ]; then
          cd ./node_modules
          for module in ./*; do
            (cd $module && check_for_binary_modules)
          done
          cd ../
        fi
      fi
    }

    check_for_binary_modules

    if [ $isBinaryModule = "yes" ]; then
      echo " > $npmModule: npm install due to binary npm modules"
      rm -rf node_modules
      npm install
      # always rebuild because the node version might be different.
      npm rebuild
      if [ -f binding.gyp ]; then
        node-gyp rebuild || :
      fi
    fi
    cd ..
  done
}

rebuild_binary_npm_modules () {
  for package in ./*; do
    if [ -d $package/node_modules ]; then
      (cd $package/node_modules && \
        gyp_rebuild_inside_node_modules)
    elif [ -d $package/main/node_module ]; then
      (cd $package/node_modules && \
        gyp_rebuild_inside_node_modules )
    fi
  done
}

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
else
   mkdir current
fi
cp tmp/bundle.tar.gz current/
cd current/
tar xzf bundle.tar.gz
cd bundle/programs/server/
npm install
echo "****** Rebuilding npm modules ******"
if [ -d npm ]; then
  (cd npm && rebuild_binary_npm_modules)
fi

if [ -d node_modules ]; then
  (cd node_modules && gyp_rebuild_inside_node_modules)
fi
cd ../..
if [[ -e npm/node_modules/meteor/npm-bcrypt/node_modules/bcrypt ]] ; then
  echo "******** bcrypt fix ********"
  rm -rf npm/node_modules/meteor/npm-bcrypt/node_modules/bcrypt
  npm install --update-binary -f bcrypt
  cp -r node_modules/bcrypt npm/node_modules/meteor/npm-bcrypt/node_modules/bcrypt
fi

cd $APP_DIR
# start app
sudo bash config/start.sh
