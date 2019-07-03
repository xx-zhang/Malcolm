#!/bin/bash

# Copyright (c) 2019 Battelle Energy Alliance, LLC.  All rights reserved.

SCRIPT_PATH="$(dirname $(realpath -e "${BASH_SOURCE[0]}"))"

echo "aggregator" > /etc/installer

if [[ -r "$SCRIPT_PATH"/common-init.sh ]]; then
  . "$SCRIPT_PATH"/common-init.sh

  # remove default accounts/groups we don't want, create/set directories for non-user users for stig to not complain
  CleanDefaultAccounts

  MAIN_USER="$(id -nu 1000)"
  if [[ -n $MAIN_USER ]]; then

    # fix some permisions to make sure things belong to the right person
    FixPermissions "$MAIN_USER"

    # if Malcolm's config file has never been touched, configure it now
    MAIN_USER_HOME="$(getent passwd "$MAIN_USER" | cut -d: -f6)"
    if [[ -f "$MAIN_USER_HOME"/Malcolm/firstrun ]]; then
      if [[ -r "$MAIN_USER_HOME"/Malcolm/scripts/install.py ]]; then
        /usr/bin/env python3.7 "$MAIN_USER_HOME"/Malcolm/scripts/install.py --configure --defaults --logstash-expose
      fi
      if [[ -r "$MAIN_USER_HOME"/Malcolm/scripts/auth_setup.sh ]]; then
        ln -r -s "$MAIN_USER_HOME"/Malcolm/scripts/auth_setup.sh "$MAIN_USER_HOME/Desktop/Malcolm Authentication Setup.sh"
        chown -h "$MAIN_USER:$MAIN_USER" "$MAIN_USER_HOME/Desktop/Malcolm Authentication Setup.sh"
      fi
      rm -f "$MAIN_USER_HOME"/Malcolm/firstrun
    fi

  fi

  # if we need to import prebuilt Malcolm docker images, do so now (but not if we're in a live-usb boot)
  DOCKER_DRIVER="$(docker info 2>/dev/null | grep 'Storage Driver' | cut -d' ' -f3)"
  if [[ -n $DOCKER_DRIVER ]] && [[ "$DOCKER_DRIVER" != "vfs" ]] && [[ -r /malcolm_images.tar.gz ]]; then
    docker load -q -i /malcolm_images.tar.gz && rm -f /malcolm_images.tar.gz
  fi

  exit 0
else
  exit 1
fi