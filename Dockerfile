FROM fedora:20
MAINTAINER "Jason Brooks" <jbrooks@redhat.com>


RUN cd /etc/yum.repos.d && curl -O http://copr-fe.cloud.fedoraproject.org/coprs/walters/rpm-ostree/repo/fedora-20-i386/walters-rpm-ostree-fedora-20-i386.repo
RUN yum install deltarpm -y; yum clean all
RUN yum -y update; yum clean all 
RUN yum install -y git rpm-ostree nss-altfiles yum-plugin-protectbase httpd; yum clean all
RUN git clone https://github.com/jasonbrooks/byo-atomic.git
RUN sed -i 's/passwd\: files/passwd\: files altfiles/g' /etc/nsswitch.conf; sed -i 's/group\: files/group\: files altfiles/g' /etc/nsswitch.conf
RUN mkdir -p /srv/rpm-ostree/repo && cd /srv/rpm-ostree/ && ostree --repo=repo init --mode=archive-z2
ADD rpm-ostree.conf /etc/httpd/conf.d/

RUN yum -y install strace rpm-ostree-toolbox kernel
RUN depmod $(cd /lib/modules && echo *) #uncache 
RUN mv /usr/bin/rpm-ostree-toolbox{,.real}
ADD rpm-ostree-toolbox-docker-wrapper /usr/bin/rpm-ostree-toolbox
RUN chmod +x /usr/bin/rpm-ostree-toolbox

EXPOSE 80

# Simple startup script to avoid some issues observed with container restart
ADD run-apache.sh /run-apache.sh
RUN chmod -v +x /run-apache.sh

CMD ["/run-apache.sh"]

#RUN cd /root/byo-atomic/c7; \
#rpm-ostree compose tree --repo=/srv/rpm-ostree/repo centos-atomic-server-docker-host.json; \
#rpm-ostree-toolbox create-vm-disk /srv/rpm-ostree/repo centos-atomic-host centos-atomic/7/x86_64/server/docker-host c7-atomic.qcow2
