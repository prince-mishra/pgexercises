#!/bin/bash

#sudo /etc/init.d/tomcat7 start
#sudo /etc/init.d/nginx start

#CMD=$(ls -1 /usr/lib/postgresql/*/bin/postgres | sort -r | head -n 1)

#cd /etc/postgresql/9.5/main

# Handoff to PostgreSQL
#exec /usr/bin/env -i "${CMD}" --config-file=postgresql.conf
service postgresql start

while ! pg_isready; do echo "waiting for postgres" & sleep 5; done

pg_isready
service tomcat7 start
service nginx start
tail -f /dev/null
