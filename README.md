Build Your Own Atomic
================

If you'd like to:

* Build your own copy of the Fedora Atomic or CentOS Atomic images, or
* Compose and serve up updates or different package sets for an Atomic host...

...then this might be the howto for you.

Atomic hosts are made of regular, already-built RPMs, composed into trees with rpm-ostree. These trees are built into various sorts of images. Here's how you can start with a bunch of Fedora or CentOS rpms, and end up with an atomic tree and ready-to-use atomic images.

## Step One: prep a build machine

Start with a Fedora 23 machine, bare metal or VM (with nested virt enabled), and install some packages:

```
$ sudo dnf update -y
$ sudo dnf install -y git docker polipo rpm-ostree-toolbox libvirt
```

Then, start up some services:

```
$ sudo systemctl enable polipo
$ sudo systemctl start polipo
$ sudo systemctl enable libvirtd
$ sudo systemctl start libvirtd
```

Finally, do a bit of prep for the ostree tree we'll be composing, and create a build directory:

```
$ sudo mkdir -p /srv/repo
$ sudo ostree --repo=/srv/repo init --mode=archive-z2
$ mkdir build
$ ln -s /srv/repo/ build/repo
```

## Step Two: get atomic host metadata

**For Fedora 23:**

```
$ git clone https://pagure.io/fedora-atomic.git
$ cd fedora-atomic
$ git checkout f23
$ curl -o fedora-23-updates.repo https://git.fedorahosted.org/cgit/fedora-repos.git/plain/fedora-updates.repo?h=f23
$ sed -i 's/\$releasever/23/g' fedora-23-updates.repo
$ cd ..

$ git clone https://git.fedorahosted.org/git/spin-kickstarts.git
$ cd spin-kickstarts
$ git checkout f23
$ cd ..
```

**For CentOS 7:**

```
$ git clone https://github.com/CentOS/sig-atomic-buildscripts
$ cd sig-atomic-buildscripts
$ git checkout downstream
$ cd ..
```

## Step Three: customize the metadata to your liking

The contents of an rpm-ostree tree are defined in one of the json files we grabbed above. The tree manifest syntax is documented [here](https://github.com/projectatomic/rpm-ostree/blob/master/docs/manual/treefile.md).

For example, to produce a version of the Fedora Atomic or CentOS Atomic tree that adds the fortune command, edit either `fedora-atomic/fedora-atomic-docker-host.json` or `sig-atomic-buildscripts/centos-atomic-host.json`, and, in the file's `"packages":` section, insert a line like this: `"fortune-mod",`.


## Step Four: compose the tree

*Change the GitDir value to match your build machine, the value below works w/ my Vagrantfile*

**For Fedora 23:**

```
$ cd build
$ GitDir=/home/vagrant/fedora-atomic; sudo rpm-ostree compose tree --repo=/srv/repo --proxy=http://127.0.0.1:8123 ${GitDir}/fedora-atomic-docker-host.json
```

**For CentOS 7:**

```
$ cd build
$ GitDir=/home/vagrant/sig-atomic-buildscripts; sudo rpm-ostree compose tree --repo=/srv/repo --proxy=http://127.0.0.1:8123 ${GitDir}/centos-atomic-host.json
```

### To build or not build images

Before we continue with the image building, note that you don't have to build your own images to have a custom Atomic host. You can compose your own updates and apply them, or even rebase to a completely different tree. I've rebased between CentOS and Fedora, for instance.

If you're going to start with an existing Atomic host (for instance, the ones behind [the buttons here](http://www.projectatomic.io/download/), you can compose and serve up a new tree from a Docker container running on that very image, or from any web server. 

In this case, you could rsync `/srv/repo` to a web server or do something like `cd /srv/repo && python -m SimpleHTTPServer 8080 &` to host the repo right from where we built it. Then, to configure an existing Atomic host to receive updates from your build machine, you could run a pair of commands like the following to add a new `withfortune` repo definition to your host, and then rebase to that tree:

```
$ sudo ostree remote add withfortune http://$YOUR_IP:8080/repo --no-gpg-verify

$ sudo rpm-ostree rebase withfortune:fedora-atomic/f23/x86_64/docker-host
```

If you *do* want to build your own images, keep reading.

## Step Five: build images

**For Fedora 23:**

```
$ GitDir=/home/vagrant/fedora-atomic; BuildDir=/home/vagrant/build; KsDir=/home/vagrant/spin-kickstarts; sudo rpm-ostree-toolbox imagefactory --overwrite --tdl ${GitDir}/fedora-atomic-f23.tdl -c  ${GitDir}/config.ini -i kvm -i vagrant-libvirt -i vagrant-virtualbox -k ${KsDir}/fedora-cloud-atomic.ks --vkickstart ${KsDir}/fedora-cloud-atomic-vagrant.ks -o ${BuildDir}/virt
```

**For CentOS 7:**

*This part creates an install tree and install iso, where Fedora uses an existing, external tree. The python simpleserver bit makes this tree available to the following stage of the process.*

```
$ GitDir=/home/vagrant/sig-atomic-buildscripts; BuildDir=/home/vagrant/build; sudo rpm-ostree-toolbox installer --overwrite --ostreerepo ${BuildDir}/repo -c ${GitDir}/config.ini -o ${BuildDir}/installer
$ python -m SimpleHTTPServer 8000 &
```

*This part creates the qcow2, vagrant libvirt and vagrant virtualbox images.*

```
$ GitDir=/home/vagrant/sig-atomic-buildscripts; BuildDir=/home/vagrant/build; sudo rpm-ostree-toolbox imagefactory --overwrite --tdl ${GitDir}/atomic-7.1.tdl -c  ${GitDir}/config.ini -i kvm -i vagrant-libvirt -i vagrant-virtualbox -k ${GitDir}/atomic-7.1-cloud.ks --vkickstart ${GitDir}/atomic-7.1-vagrant.ks -o ${BuildDir}/virt
```

For both Fedora and CentOS, you should find your images in `build/virt/images`. The CentOS ISO will end up in `build/installer/images/images`. Fedora builds its install ISO differently... I need to look that part up if I'm to include build steps here.

## Future updates

After you've created your image(s), future runs of the `rpm-ostree compose tree` command from step four above will add updated packages to your repo, which you can pull down to an Atomic instance. For more information on configuring an Atomic host to consume custom updates, scroll back up to "To build or not build images," above.

## Converting images to .vdi (if desired)

These scripts produce qcow2 images, which are ready to use with OpenStack or with virt-manager/virsh. To produce *.vdi images, use qemu-img to convert:

`qemu-img convert -f qcow2 c7-atomic.qcow2 -O vdi c7-atomic.vdi`


## How to log in?

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

