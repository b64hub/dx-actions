FROM --platform=linux/amd64 node:20.2-alpine3.17 as build

ARG SFPOWERSCRIPTS_VERSION=alpha
ENV DEBIAN_FRONTEND=noninteractive 
ENV SHELL /bin/bash

RUN apk update && apk add --no-cache \
  alpine-sdk \
  python3

# ENV PATH="/usr/local/lib/node_modules:$PATH"
ENV PYTHON=/usr/bin/python3
ENV XDG_DATA_HOME=/sfdx_plugins/.local/share \
    XDG_CONFIG_HOME=/sfdx_plugins/.config  \
    XDG_CACHE_HOME=/sfdx_plugins/.cache

#
# Create isolated plugins directory with rwx permission for all users
# Azure pipelines switches to a container-user which does not have access
# to the root directory where plugins are normally installed
RUN mkdir -p $XDG_DATA_HOME $XDG_CONFIG_HOME $XDG_CACHE_HOME \
    && chmod -R 777 sfdx_plugins

# Install sfpowerscripts package dependecies and plugins
RUN npm install --global sfdx-cli --ignore-scripts \
  && npm install --global @salesforce/cli \ 
  && echo 'y' | sfdx plugins install sfdx-browserforce-plugin@2.9.1 \
  && echo 'y' | sfdx plugins install sfdmu@4.18.2 \
  && npm install -g @dxatscale/sfpowerscripts@$SFPOWERSCRIPTS_VERSION \
  && npm cache clean --force


FROM --platform=linux/amd64 node:20.2-alpine3.17

ENV SHELL=/bin/bash
ENV SFDX_CONTAINER_MODE=true 

RUN apk update && apk add --no-cache jq openjdk11

COPY --from=build /sfdx_plugins/.local/share /sfdx_plugins/.local/share
COPY --from=build /usr/local/lib/node_modules /usr/local/lib/node_modules
COPY --from=build /usr/local/bin /usr/local/bin

ENV XDG_DATA_HOME=/sfdx_plugins/.local/share \
    XDG_CONFIG_HOME=/sfdx_plugins/.config  \
    XDG_CACHE_HOME=/sfdx_plugins/.cache \
    JAVA_HOME=/usr/lib/jvm/java-11-openjdk

