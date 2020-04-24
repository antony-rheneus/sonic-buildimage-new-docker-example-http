#!/usr/bin/env bash

# Generate supervisord config file
mkdir -p /etc/supervisor/conf.d/
sonic-cfggen -d -t /usr/share/sonic/templates/docker-bigfoot.supervisord.conf.j2 > /etc/supervisor/conf.d/docker-bigfoot.supervisord.conf

# The docker container should start this script as PID 1, so now that supervisord is
# properly configured, we exec supervisord so that it runs as PID 1 for the
# duration of the container's lifetime
exec /usr/bin/supervisord
