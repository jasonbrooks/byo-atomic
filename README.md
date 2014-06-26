c7-atomic
=========

Build a centos 7-based atomic host, rough directions

* clone this git repo and cd into it
* configure Colin's rpm-ostree copr repo: http://copr.fedoraproject.org/coprs/walters/rpm-ostree/ on your host
* yum install rpm-ostree-toolbox
* configure system as described at: https://github.com/projectatomic/rpm-ostree (disable selinux, nss-altfiles, set up build dir)
* sudo rpm-ostree compose tree --repo=/srv/rpm-ostree/repo centos-atomic-server-docker-host.json
* sudo rpm-ostree-toolbox create-vm-disk /srv/rpm-ostree/repo centos-atomic-host centos-atomic/7/x86_64/server/docker-host image.qcow2
