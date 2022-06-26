#!/bin/sh
docker exec -it -u root jenkins sh -c \
  'curl https://get.docker.com/ > dockerinstall &&
  chmod 777 dockerinstall &&
  ./dockerinstall &&
  chmod 666 /var/run/docker.sock'
