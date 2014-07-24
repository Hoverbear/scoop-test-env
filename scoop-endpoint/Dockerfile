### A Dockerfile!
FROM phusion/passenger-ruby19

### Add mongo repo
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10
RUN echo 'deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen' | tee /etc/apt/sources.list.d/mongodb.list

### Stuff we need
RUN apt-get update

# Needed for SCOOP
RUN apt-get --yes install ntp libxslt-dev libxml2-dev mongodb-org autossh

### ENV and User
USER app
ENV HOME /home/app/

### Install endpoint software.
WORKDIR /home/app
RUN git clone git://github.com/scoophealth/query-gateway.git
WORKDIR /home/app/query-gateway
RUN bundle install --path vendor/bundle
RUN mkdir -p /home/app/query-gateway/tmp/pids # Make PIDS

### Change back to root
USER root

### Setup Mongo
RUN mkdir -p /etc/service/mongodb/ && \
	mkdir -p /data/db && \
	chown -R mongodb /data/db
VOLUME /data/db
ADD scripts/mongodb.sh /etc/service/mongodb/run
RUN chmod +x /etc/service/mongodb/run

ADD scripts/gateway.sh /etc/service/gateway/run
RUN chmod +x /etc/service/gateway/run

ADD scripts/keys.sh /etc/service/keys/run
RUN chmod +x /etc/service/keys/run

### AutoSSH
ADD scripts/start_admin_tunnel.sh /etc/service/admin_tunnel/run
RUN chmod +x /etc/service/admin_tunnel/run
ADD scripts/start_endpoint_tunnel.sh /etc/service/endpoint_tunnel/run
RUN chmod +x /etc/service/endpoint_tunnel/run

### Expose Ports
EXPOSE 3001 22 27017

### Run Command
CMD ["/sbin/my_init"]


###
# Using SELinux?
# --------------
# chcon -Rt svirt_sandbox_file_t $(pwd)/db
###
# Starting
# --------
# NAME="endpoint-1"
# docker run --name=$NAME -d -p 3001:3001 -p 22:22 -p 27017 --link hub-1:hub endpoint
#
### Backing up the DB
# -------------------
# PORT=$(docker port $NAME 27017 | awk '{split($0,a,":"); print a[2]}')
# docker run --rm --link $NAME\:target -v $(pwd)/db:/restore mongo mongorestore -p $PORT -h target /restore
###
# Namespace entering
# ------------------
# sudo nsenter --target $(docker inspect --format {{.State.Pid}} $NAME) --mount --uts --ipc --net --pid /bin/bash
