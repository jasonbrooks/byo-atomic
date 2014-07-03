byo atomic images
================

Build a CentOS 7 or Fedora 20-based atomic host, rough directions

First, build the builder:

* install Fedora 20 (c7 should work, too, but I've found f20 to be more nested-virt friendly -- these tools use kvm during the image-building process, and if your builder is a VM, like mine is, you'll be tangling w/ nested virt.)
* disable selinux by changing `enforced` to `disabled` in `/etc/selinux/config` and then `systemctl reboot` to complete selinux disabling
* the rpm-ostree commands need to be run as root or w/ sudo, but for some reason, the image-building part of the process is only working for me while running as root (not sudo), so I log in as root and work in `/root`
* `yum install -y git`
* `git clone https://github.com/jasonbrooks/byo-atomic.git`
* `mv byo-atomic/walters-rpm-ostree-fedora-20-i386.repo /etc/yum.repos.d/`
* `yum install -y rpm-ostree rpm-ostree-toolbox nss-altfiles yum-plugin-protectbase`
* edit `/etc/nsswitch.conf` change lines `passwd: files` and `group: files` to `passwd: files altfiles` and `group: files altfiles` [(details)](https://github.com/projectatomic/rpm-ostree)
* edit `/etc/libvirt/qemu.conf` to uncomment the line `user = "root"`
* `systemctl restart libvirtd`
* `mkdir -p /srv/rpm-ostree/repo && cd /srv/rpm-ostree/ && sudo ostree --repo=repo init --mode=archive-z2`
* `cd /root/byo-atomic/c7` or, for an f20 host: `cd /root/byo-atomic/f20`
* `rpm-ostree compose tree --repo=/srv/rpm-ostree/repo centos-atomic-server-docker-host.json` (swap "centos" w/ "fedora" for an f20 host)
* `rpm-ostree-toolbox create-vm-disk /srv/rpm-ostree/repo centos-atomic-host centos-atomic/7/x86_64/server/docker-host c7-atomic.qcow2` (swap "centos" w/ "fedora" and "c7" w/ "f20" for an f20 host)
