FROM centos:centos6.6
MAINTAINER Michael Stealey <michael.j.stealey@gmail.com>

RUN yum install -y wget
RUN wget http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
RUN rpm -Uvh epel-release-6*.rpm

# Install PostgreSQL 9.3.6 pre-requisites
RUN rpm -ivh http://yum.postgresql.org/9.3/redhat/rhel-6-x86_64/pgdg-centos93-9.3-1.noarch.rpm
RUN yum install -y postgresql93 postgresql93-server postgresql93-odbc unixODBC
RUN yum install -y perl authd wget fuse-libs openssl098e curl-devel sudo which pwgen
RUN yum install -y perl-JSON python-psutil python-requests python-jsonschema

# Modify authd config file for xinetd.d
RUN cp /etc/xinetd.d/auth /var/tmp/auth
RUN sed "s/-E//g" /etc/xinetd.d/auth > /var/tmp/auth
RUN cp /var/tmp/auth /etc/xinetd.d/auth
RUN cat /etc/xinetd.d/auth
RUN rm /var/tmp/auth

# Set proper run level for authd
RUN /sbin/chkconfig --level=3 auth on

# Restart xinitd
RUN /etc/init.d/xinetd restart

# Install iRODS RPMs - uncomment packages as required
ADD files /files
WORKDIR /files
# get iRODS rpm files
RUN sh get-irods-rpms.sh
# Install irods-icat
RUN rpm -i $(ls -l | tr -s ' ' | grep irods-icat | cut -d ' ' -f 9)
# Install irods-database-plugin
RUN rpm -i $(ls -l | tr -s ' ' | grep irods-database-plugin | cut -d ' ' -f 9)

ADD scripts /scripts
WORKDIR /scripts
RUN chmod a+x *.sh

# Open firewall for iRODS
EXPOSE 1247 1248 20000-20199
ENTRYPOINT [ "/scripts/config-existing-irods.sh" ]
