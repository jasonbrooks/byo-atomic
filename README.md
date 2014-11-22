Build Your Own Atomic
================

If you'd like to:

* Build your own copy of the Atomic Fedora or Atomic CentOS test images, or
* Compose and serve up updates or different package sets for an Atomic host...

...then this might be the howto for you.

Atomic hosts are made of regular, already-built RPMs, composed into trees with rpm-ostree. These trees are built into qcow2 images (or into installable ISOs, but I'm not covering that here, yet).

Once up and running, an Atomic host can be updated by pointing to an updated tree. (If the update isn't satisfactory, you can then roll back, atomicly)

You don't have to build your own qcow2 to have a custom Atomic host. You can compose your own updates and apply them, or even rebase to a completely different tree. (I've rebased between CentOS and Fedora, for instance)

If you're going to start with an existing Atomic host (for instance, one installed from this or that image), you can compose and serve up a new tree from a Docker container. 

## Composing and hosting atomic updates 

````
# git clone --recursive https://github.com/jasonbrooks/byo-atomic.git
# docker build --rm -t $USER/atomicrepo byo-atomic/.
# docker run -ti -p 80:10080 $USER/atomicrepo bash
````

Once inside the container:

### For CentOS 7:

````
# cd /byo-atomic/sig-atomic-buildscripts
# git checkout master
# git pull
````

If you'd like to add some more packages to your tree, add them in the file `centos-atomic-cloud-docker-host.json` before proceeding with the compose command:

````
# rpm-ostree compose tree --repo=/srv/rpm-ostree/repo centos-atomic-cloud-docker-host.json
````

_The CentOS sig-atomic-buildscripts repo currently includes some key packages built in and hosted from the CentOS [Community Build System](http://cbs.centos.org/koji/). The CBS repos rebuild every 10 minutes, so if your rpm-ostree fails out w/ a repository not found sort of error, wait a few minutes and run the command again._

### For Fedora 21:

The master branch of the fedora-atomic repo contains the definitions required to compose a rawhide-based Fedora Atomic host. If you'd rather compose a f21-based Fedora Atomic host, you'll need to:

````
# cd /byo-atomic/fedora-atomic
# git checkout f21
# git pull
````

If you'd like to add some more packages to your tree, add them in the file `fedora-atomic-docker-host.json` before proceeding with the compose command:

````
# rpm-ostree compose tree --repo=/srv/rpm-ostree/repo fedora-atomic-docker-host.json
````

### For both Fedora and CentOS:
 
The compose step will take some time to complete. When it's done, you can run the following command to start up a web server in the container. 

````
# sh /run-apache.sh
````

Now, you should be able to visit $YOURHOSTIP:10080/repo and see your new rpm-ostree repo. 

To configure an Atomic host to receive updates from your build machine, edit (as root) the file `/ostree/repo/config` and add a section like this:

````
[remote "centos-atomic-host"]
url=http://$YOURHOSTIP:10080/repo
branches=centos/7/x86_64/cloud-docker-host;
gpg-verify=false
````

````
[remote "fedora-atomic-host"]
url=http://$YOURHOSTIP:10080/repo
branches=fedora-atomic/21/x86_64/docker-host;
gpg-verify=false
````

With your repo configured, you can check for updates with the command `sudo rpm-ostree upgrade`, followed by a reboot. Don't like the changes? You can rollback with `rpm-ostree rollback`, followed by another reboot.


## Optional: Create your own Atomic image

First, build and configure the builder. Install Fedora 21 (Fedora 20 or CentOS 7 can work, too, but F21 includes the rpm-ostree packages we need by default, now, so that's what I'm using here). You can build trees and images for Fedora or CentOS from the same builder, and the versions don't have to match.

Disable selinux by changing `enforced` to `disabled` in `/etc/selinux/config` and then `systemctl reboot` to complete selinux disabling. While we're never happy about disabling SELinux, it's necessary ([for now](https://bugzilla.redhat.com/show_bug.cgi?id=1060423)) to disable it on your builder in order to enable it on the Atomic instances you build.

The rpm-ostree commands below need to be run as root or w/ sudo, but for some reason, the image-building part of the process is only working for me while running as root (not sudo), so I log in as root and work in `/root`.

````
# yum install -y git 
# git clone --recursive https://github.com/jasonbrooks/byo-atomic.git
# yum install -y rpm-ostree rpm-ostree-toolbox nss-altfiles yum-plugin-protectbase httpd
````

Now, we'll set up a repository from which our eventual Atomic hosts will fetch upgrades:

````
# mkdir -p /srv/rpm-ostree/repo && cd /srv/rpm-ostree/ && sudo ostree --repo=repo init --mode=archive-z2
# cat > /etc/httpd/conf.d/rpm-ostree.conf <<EOF
DocumentRoot /srv/rpm-ostree
<Directory "/srv/rpm-ostree">
Options Indexes FollowSymLinks
AllowOverride None
Require all granted
</Directory>
EOF
# systemctl daemon-reload &&
systemctl enable httpd &&
systemctl start httpd &&
systemctl reload httpd &&
firewall-cmd --add-service=http &&
firewall-cmd --add-service=http --permanent
````

Next, we compose a tree for our Atomic host image:

This repository includes submodules that provide the *.json files maintained by the Fedora Cloud SIG (keeper of the Atomic Fedora definition) and the Atomic CentOS SIG. If you'd like to add some more packages to your tree, add them in the file `sig-atomic-buildscripts/centos-atomic-cloud-docker-host.json` or `fedora-atomic/fedora-atomic-docker-host.json` before proceeding.

### For CentOS 7:

````
# cd /root/byo-atomic/sig-atomic-buildscripts
# rpm-ostree compose tree --repo=/srv/rpm-ostree/repo centos-atomic-cloud-docker-host.json
````

This step will take a while to complete. When it's finished, you can move on to creating the disk image:

````
# export LIBGUESTFS_BACKEND=direct
# rpm-ostree-toolbox create-vm-disk /srv/rpm-ostree/repo centos-atomic-host centos/7/atomic/x86_64/cloud-docker-host centos-atomic.qcow2
````

### For Fedora 21:

````
# cd /root/byo-atomic/fedora-atomic
# git checkout f21
# rpm-ostree compose tree --repo=/srv/rpm-ostree/repo fedora-atomic-docker-host.json
````

This step will take a while to complete. When it's finished, you can move on to creating the disk image:

````
# export LIBGUESTFS_BACKEND=direct
# rpm-ostree-toolbox create-vm-disk /srv/rpm-ostree/repo fedora-atomic-host fedora-atomic/21/x86_64/server/docker-host f21-atomic.qcow2
````

After you've created your image(s), future runs of the `rpm-ostree compose tree` command will add updated packages to your repo, which you can pull down to an Atomic instance. For more information on updating, see "Configuring your Atomic instance to receive updates," below.

### Converting images to .vdi (if desired)

These scripts produce qcow2 images, which are ready to use with OpenStack or with virt-manager/virsh. To produce *.vdi images, use qemu-img to convert:

`qemu-img convert -f qcow2 c7-atomic.qcow2 -O vdi c7-atomic.vdi`


### How to log in?

Your atomic images will be born with no root password, so it's necessary to supply a password or key to log in using cloud-init. If you're using a virtualization application without cloud-init support, such as virt-manager or VirtualBox, you can create a simple iso image to provide a key or password to your image when it boots.

To create this iso image, you must first create two text files.

Create a file named "meta-data" that includes an "instance-id" name and a "local-hostname." For instance: 

````
instance-id: Atomic0
local-hostname: atomic-00
````

The second file is named "user-data," and includes password and key information. For instance:

````
#cloud-config
password: atomic
chpasswd: {expire: False}
ssh_pwauth: True
ssh_authorized_keys:
  - ssh-rsa AAA...SDvz user1@yourdomain.com
  - ssh-rsa AAB...QTuo user2@yourdomain.com
````

Once you have completed your files, they need to packaged into an ISO image. For instance:

````
# genisoimage -output atomic0-cidata.iso -volid cidata -joliet -rock user-data meta-data
````
You can boot from this iso image, and the auth details it contains will be passed along to your Atomic instance.

For more information about creating these cloud-init iso images, see http://cloudinit.readthedocs.org/en/latest/topics/datasources.html#config-drive.

