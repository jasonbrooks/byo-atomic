c7-atomic
=========

Build a centos 7-based atomic host, rough directions

First, build the builder:

* install Fedora 20
* disable selinux by changing `enforced` to `disabled` in `/etc/selinux/config` and then `systemctl reboot` to complete selinux disabling
* the rpm-ostree commands need to be run as root or w/ sudo, but for some reason, the image-building part of the process is only working for me while running as root (not sudo), so I log in as root and work in `/root`
* `sudo yum install -y git`
* `git clone https://github.com/jasonbrooks/c7-atomic.git`
* `sudo mv c7-atomic/walters-rpm-ostree-fedora-20-i386.repo /etc/yum.repos.d/`
* `sudo yum install -y rpm-ostree rpm-ostree-toolbox nss-altfiles yum-plugin-protectbase`
* edit `/etc/nsswitch.conf` change lines `passwd: files` and `group: files` to `passwd: files altfiles` and `group: files altfiles` [1](https://github.com/projectatomic/rpm-ostree)
* edit `/etc/libvirt/qemu.conf` to uncomment the line `user = "root"`
* `systemctl restart libvirtd`
* `sudo mkdir -p /srv/rpm-ostree/repo && cd /srv/rpm-ostree/ && sudo ostree --repo=repo init --mode=archive-z2`
* `cd /root/c7-atomic`
* `sudo rpm-ostree compose tree --repo=/srv/rpm-ostree/repo centos-atomic-server-docker-host.json`
* `sudo rpm-ostree-toolbox create-vm-disk /srv/rpm-ostree/repo centos-atomic-host centos-atomic/7/x86_64/server/docker-host c7-atomic.qcow2`
