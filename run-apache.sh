#!/bin/bash


# comment here

exec /usr/sbin/nscd


# Make sure we're not confused by old, incompletely-shutdown httpd
# context after restarting the container.  httpd won't start correctly
# if it thinks it is already running.

rm -rf /run/httpd/*

exec /usr/sbin/apachectl -D FOREGROUND
