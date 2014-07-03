byo atomic images
================

Build a CentOS 7 or Fedora 20-based atomic host, rough directions

First, build and configure the builder:

* install Fedora 20 (c7 should work, too, but I've found f20 to be more nested-virt friendly -- these tools use kvm during the image-building process, and if your builder is a VM, like mine is, you'll be tangling w/ nested virt.)
* disable selinux by changing `enforced` to `disabled` in `/etc/selinux/config` and then `systemctl reboot` to complete selinux disabling
* the rpm-ostree commands need to be run as root or w/ sudo, but for some reason, the image-building part of the process is only working for me while running as root (not sudo), so I log in as root and work in `/root`
* `yum install -y git`
* `git clone https://github.com/jasonbrooks/byo-atomic.git`
* `mv byo-atomic/walters-rpm-ostree-fedora-20-i386.repo /etc/yum.repos.d/`
* `yum install -y rpm-ostree rpm-ostree-toolbox nss-altfiles yum-plugin-protectbase httpd`
* edit `/etc/nsswitch.conf` change lines `passwd: files` and `group: files` to `passwd: files altfiles` and `group: files altfiles` [(details)](https://github.com/projectatomic/rpm-ostree)
* edit `/etc/libvirt/qemu.conf` to uncomment the line `user = "root"`
* `systemctl restart libvirtd`
* `mkdir -p /srv/rpm-ostree/repo && cd /srv/rpm-ostree/ && sudo ostree --repo=repo init --mode=archive-z2
* `cat > /etc/httpd/conf.d/rpm-ostree.conf <<EOF
DocumentRoot /srv/rpm-ostree
<Directory "/srv/rpm-ostree">
Options Indexes FollowSymLinks
AllowOverride None
Require all granted
</Directory>
EOF`
* systemctl daemon-reload &&
systemctl enable httpd &&
systemctl start httpd &&
systemctl reload httpd &&
firewall-cmd --add-service=http &&
firewall-cmd --add-service=http --permanent

Next, build the Atomic host:

For CentOS 7:

* `cd /root/byo-atomic/c7` 
* `rpm-ostree compose tree --repo=/srv/rpm-ostree/repo centos-atomic-server-docker-host.json`
* `rpm-ostree-toolbox create-vm-disk /srv/rpm-ostree/repo centos-atomic-host centos-atomic/7/x86_64/server/docker-host c7-atomic.qcow2`

For Fedora 20:

* `cd /root/byo-atomic/f20`
* `rpm-ostree compose tree --repo=/srv/rpm-ostree/repo fedora-atomic-server-docker-host.json`
* `rpm-ostree-toolbox create-vm-disk /srv/rpm-ostree/repo fedora-atomic-host fedora-atomic/20/x86_64/server/docker-host f20-atomic.qcow2`

These scripts produce qcow2 images, which are ready to use with OpenStack or with virt-manager/virsh. To produce *.vdi images, use qemu-img to convert:

`qemu-img convert -f qcow2 c7-atomic.qcow2 -O vdi c7-atomic.vdi`

The atomic images are born with no root password, so it's necessary to supply a password or key to log in using cloud-init. If you're using a virtualization application without cloud-init support, such as virt-manager or VirtualBox, you can create a simple iso image to provide a key or password to your image when it boots.


