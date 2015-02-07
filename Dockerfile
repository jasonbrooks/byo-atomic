FROM fedora:21
MAINTAINER "Jason Brooks" <jbrooks@redhat.com>


RUN yum update -y; \
yum install -y pykickstart rpm-ostree-toolbox httpd git nscd; \
yum clean all

RUN git clone --recursive https://github.com/jasonbrooks/byo-atomic.git
RUN mkdir -p /srv/rpm-ostree/repo && cd /srv/rpm-ostree/ && ostree --repo=repo init --mode=archive-z2
ADD rpm-ostree.conf /etc/httpd/conf.d/

EXPOSE 80

# Simple startup script to avoid some issues observed with container restart
ADD run-apache.sh /run-apache.sh
RUN chmod -v +x /run-apache.sh

CMD ["/run-apache.sh"]

