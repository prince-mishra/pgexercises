FROM ubuntu:16.04
MAINTAINER Feike Steenbergen <feike.steenbergen@zalando.de>

RUN echo 'APT::Install-Recommends "0";' > /etc/apt/apt.conf.d/01norecommend
RUN echo 'APT::Install-Suggests "0";' >> /etc/apt/apt.conf.d/01norecommend

ENV PGVERSION 9.5

# To reduce the Docker image size, we combine some steps into 1 step
RUN apt-get update -y \
 && apt-get -y install build-essential postgresql-${PGVERSION} nginx perl libwww-perl libjson-perl curl less vim sudo \
 && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8 \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists

ADD . /pgexercises

RUN perl /pgexercises/cpanm HTML::Make
#RUN cpanm HTML::Make
RUN cp /pgexercises/nginx/nginx-dev.conf /etc/nginx/nginx.conf

WORKDIR /pgexercises
RUN sed -i 's|jdbc:postgresql://localhost:6543/exercises|jdbc:postgresql://localhost:5432/exercises|' database/context.xml \
 && sed -i 's|password=""|password="none"|g' database/context.xml
#RUN mkdir -p /var/lib/tomcat7/conf && cp database/context.xml /var/lib/tomcat7/conf
RUN echo "listen_addresses='*'" >> /etc/postgresql/${PGVERSION}/main/postgresql.conf
RUN cp -a /etc/postgresql/${PGVERSION}/main/pg_hba.conf /etc/postgresql/${PGVERSION}/main/pg_hba.conf.bak \
 && echo "local all all trust" > /etc/postgresql/${PGVERSION}/main/pg_hba.conf \
 && echo "host all all all trust" >> /etc/postgresql/${PGVERSION}/main/pg_hba.conf \
 && service postgresql start && pg_isready \
 && psql -U postgres -f database/clubdata-createusersonly.sql \
 && psql -U postgres -f database/clubdata-createrwdbs-10.sql \
 && psql -U postgres -f database/clubdata.sql \
 && psql -U postgres -c "ALTER USER pgexercises WITH PASSWORD 'none'" \
 && cd scripts \
 ## This is beyong ugly, I need to hack a hack
 && sed -i 's/psql93/psql/g' runpsql \
# 
# && ./processdocs.pl ../ 1 \
 && echo "listen_addresses='*'" >> /etc/postgresql/${PGVERSION}/main/postgresql.conf \
 && mkdir -p /usr/local/nginx && ln -s /pgexercises/site /usr/local/nginx/site

RUN apt-get update -y && apt-get -y install ant tomcat7 openjdk-8-jdk
#  added
# && service tomcat7 restart \
# && service nginx restart
# && ./processdocs.pl ../ 1 
WORKDIR /pgexercises/SQLForwarder
RUN mkdir -p WebContent/WEB-INF/lib
RUN echo "tomcatlib.dir=/usr/share/tomcat7/lib/" > build.properties

#RUN mv lib/*.jar /usr/share/tomcat7/lib/
RUN mv WebContent/WEB-INF/lib/*.jar /usr/share/tomcat7/lib/
RUN ant war
RUN mv build/war/SQLForwarder.war /var/lib/tomcat7/webapps

RUN cp /pgexercises/database/context.xml /var/lib/tomcat7/conf
RUN usermod -a -G adm postgres
RUN echo "postgres ALL=(ALL:ALL) NOPASSWD: /etc/init.d/tomcat7 start, /etc/init.d/tomcat7 stop, /etc/init.d/tomcat7 restart" >> /etc/sudoers \
 && echo "postgres ALL=(ALL:ALL) NOPASSWD: /etc/init.d/nginx start, /etc/init.d/nginx stop, /etc/init.d/nginx restart" >> /etc/sudoers
#RUN cd ..
#RUN cd /pgexercises/scripts && ./processdocs.pl ../ 1 
EXPOSE 80 5432

ADD docker_entrypoint.sh /docker_entrypoint.sh
#RUN chown postgres:postgres /docker_entrypoint.sh
#RUN chmod -R 777 /pgexercises
#USER postgres
CMD ["/bin/bash", "/docker_entrypoint.sh"]
