# ------------------------------------------------------------------------------
# Based on a work at https://github.com/kdelfour/cloud9-docker
# ------------------------------------------------------------------------------
# Pull base image.
FROM ubuntu
MAINTAINER Elton Minetto <eminetto@gmail.com>

# Install Supervisor.
RUN \
    apt-get update && \
    apt-get install -y supervisor build-essential g++ curl libssl-dev apache2-utils git libxml2-dev sshfs locales && \
    rm -rf /var/lib/apt/lists/* && \
    sed -i 's/^\(\[supervisord\]\)$/\1\nnodaemon=true/' /etc/supervisor/supervisord.conf

# Define mountable directories.
VOLUME ["/etc/supervisor/conf.d"]

# ------------------------------------------------------------------------------
# Security changes
# - Determine runlevel and services at startup [BOOT-5180]
RUN update-rc.d supervisor defaults

# - Check the output of apt-cache policy manually to determine why output is empty [KRNL-5788]
RUN apt-get update | apt-get upgrade -y

# - Install a PAM module for password strength testing like pam_cracklib or pam_passwdqc [AUTH-9262]
RUN apt-get install libpam-cracklib nodejs npm -y
RUN ln -s /lib/x86_64-linux-gnu/security/pam_cracklib.so /lib/security

RUN locale-gen en_US.UTF-8

# ------------------------------------------------------------------------------
# Install Cloud9
RUN git clone https://github.com/c9/core.git /cloud9
WORKDIR /cloud9
RUN scripts/install-sdk.sh

# Tweak standlone.js conf
RUN sed -i -e 's_127.0.0.1_0.0.0.0_g' /cloud9/configs/standalone.js 


# Install challenges dependencies
# python deps
RUN apt-get install -y python3-pip python-pip default-jdk && \
    pip3 install virtualenv && \
    curl -O https://storage.googleapis.com/golang/go1.11.2.linux-amd64.tar.gz && \
    tar -xvf go1.11.2.linux-amd64.tar.gz && \
    mv go /usr/local && \
    rm -f go1.11.2.linux-amd64.tar.gz && \
    echo 'PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/usr/local/go/bin:/codenation"' > /etc/profile 

# Go 
# Java
# codenation cli

# Add supervisord conf
ADD conf/cloud9.conf /etc/supervisor/conf.d/

# ------------------------------------------------------------------------------
# Add volumes
RUN mkdir /root/codenation
VOLUME /root/codenation
VOLUME /codenation

# ------------------------------------------------------------------------------
# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# ------------------------------------------------------------------------------
# Expose ports.
EXPOSE 80
EXPOSE 3000

# ------------------------------------------------------------------------------
# Start supervisor, define default command.
CMD ["supervisord", "-c", "/etc/supervisor/supervisord.conf"]