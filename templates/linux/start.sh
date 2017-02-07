#!/bin/bash

APPNAME=<%= appName %>
APP_PATH=/opt/$APPNAME
BUNDLE_PATH=$APP_PATH/current
ENV_FILE=$APP_PATH/config/env.list
PORT=<%= port %>
USE_LOCAL_MONGO=<%= useLocalMongo? "1" : "0" %>
LINK_MAIL=<%= noMail ? "0" : "1" %>
PUBLISH_NETWORK=<%= publishNetwork ? publishNetwork : "127.0.0.1" %>
DOCKERIMAGE=<%= useMeteor4 ? "mgonand/dockerimages:meteor4" : "mgonand/dockerimages:meteor" %>

# Remove previous version of the app, if exists
docker rm -f $APPNAME

# Remove frontend container if exists
docker rm -f $APPNAME-frontend

# We don't need to fail the deployment because of a docker hub downtime
set +e
docker pull $DOCKERIMAGE
set -e

if [ "$USE_LOCAL_MONGO" == "1" ]; then
  if [ "$LINK_MAIL" == "1" ]; then
    docker run \
      -d \
      --restart=always \
      --publish=$PUBLISH_NETWORK:$PORT:80 \
      --volume=$BUNDLE_PATH:/bundle \
      --volume=/opt/backups:/backups \
      --env-file=$ENV_FILE \
      --link=mongodb:mongodb \
      --link=mail:mail \
      --hostname="$HOSTNAME-$APPNAME" \
      --env=MONGO_URL=mongodb://mongodb:27017/$APPNAME \
      --name=$APPNAME \
      $DOCKERIMAGE
  else
    docker run \
      -d \
      --restart=always \
      --publish=$PUBLISH_NETWORK:$PORT:80 \
      --volume=$BUNDLE_PATH:/bundle \
      --volume=/opt/backups:/backups \
      --env-file=$ENV_FILE \
      --link=mongodb:mongodb \
      --hostname="$HOSTNAME-$APPNAME" \
      --env=MONGO_URL=mongodb://mongodb:27017/$APPNAME \
      --name=$APPNAME \
      $DOCKERIMAGE
  fi
else
  if [ "$LINK_MAIL" == "1" ]; then
    docker run \
      -d \
      --restart=always \
      --publish=$PUBLISH_NETWORK:$PORT:80 \
      --volume=$BUNDLE_PATH:/bundle \
      --volume=/opt/backups:/backups \
      --env-file=$ENV_FILE \
      --link=mongodb:mongodb \
      --link=mail:mail \
      --hostname="$HOSTNAME-$APPNAME" \
      --name=$APPNAME \
      $DOCKERIMAGE
  else
    docker run \
      -d \
      --restart=always \
      --publish=$PUBLISH_NETWORK:$PORT:80 \
      --volume=$BUNDLE_PATH:/bundle \
      --volume=/opt/backups:/backups \
      --env-file=$ENV_FILE \
      --link=mongodb:mongodb \
      --hostname="$HOSTNAME-$APPNAME" \
      --name=$APPNAME \
      $DOCKERIMAGE
  fi
fi
