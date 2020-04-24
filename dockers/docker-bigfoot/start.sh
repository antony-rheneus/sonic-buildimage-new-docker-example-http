#!/usr/bin/env bash

# Remove stale rsyslog PID file if it exists
rm -f /var/run/rsyslogd.pid

# Start rsyslog
supervisorctl start rsyslogd

cd /etc/apache2/mods-enabled
ln -s -f ../mods-available/cgi.load . || true
ln -s -f ../mods-available/cgid.load . || true
service apache2 start

