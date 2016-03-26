FROM fedora:21
MAINTAINER "Jason Brooks" <jbrooks@redhat.com>


RUN yum update -y; \
yum install -y rpm-ostree httpd git nscd; \
yum clean all

RUN mkdir -p /home/working; \

cd /home/working; \

git clone https://github.com/CentOS/sig-atomic-buildscripts; \

git clone https://git.fedorahosted.org/git/fedora-atomic.git; \

mkdir -p /srv/rpm-ostree/repo && cd /srv/rpm-ostree/ && ostree --repo=repo init --mode=archive-z2; \

mkdir -p /var/log/httpd

ADD rpm-ostree.conf /etc/httpd/conf.d/

EXPOSE 80

# Simple startup script to avoid some issues observed with container restart

ADD run-apache.sh /run-apache.sh

RUN chmod -v +x /run-apache.sh

WORKDIR /home/working
CMD ["/run-apache.sh"]

