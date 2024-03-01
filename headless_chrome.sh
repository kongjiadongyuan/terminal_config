#!/bin/sh
docker run -d --rm --name chromium \
  -e TZ=Etc/UTC \
  -e LC_ALL=zh_CN.UTF-8 \
  -e INSTALL_PACKAGES=fonts-noto-cjk \
  -e DOCKER_MODS=linuxserver/mods:universal-internationalization \
  -p 3000:3000 \
  -p 3001:3001 \
  lscr.io/linuxserver/chromium:latest
