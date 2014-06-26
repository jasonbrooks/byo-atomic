c7-atomic
=========

Build a centos 7-based atomic host, rough directions

First, build the builder:

* install Fedora 20 (or CentOS 7)
* curl -O 
* * `yum install -y git`
* `git clone https://github.com/jasonbrooks/c7-atomic.git`
* configure Colin's rpm-ostree copr repo: http://copr.fedoraproject.org/coprs/walters/rpm-ostree/ on your host
* yum install -y rpm-ostree rpm-ostree-toolbox
* configure system as described at: https://github.com/projectatomic/rpm-ostree (disable selinux, nss-altfiles, set up build dir)
* cd into this git repo
* sudo rpm-ostree compose tree --repo=/srv/rpm-ostree/repo centos-atomic-server-docker-host.json
* sudo rpm-ostree-toolbox create-vm-disk /srv/rpm-ostree/repo centos-atomic-host centos-atomic/7/x86_64/server/docker-host image.qcow2
