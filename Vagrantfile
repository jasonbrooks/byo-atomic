Vagrant.configure(2) do |config|

  config.vm.box = "fedora/23-cloud-base"

  config.vm.provider "libvirt" do |libvirt, override|
    libvirt.cpus = 2
    libvirt.memory = 4096
    libvirt.driver = 'kvm'
    libvirt.nested = true
    libvirt.storage :file, :size => '20G'
  end

  config.vm.synced_folder ".", "/vagrant", disabled: true

$script = <<SCRIPT

# install updates and needed packages

dnf update -y
dnf install -y git docker polipo rpm-ostree-toolbox libvirt

# turn on polipo & libvirt

systemctl enable polipo
systemctl start polipo
systemctl enable libvirtd
systemctl start libvirtd

# set up for docker

systemctl start lvm2-lvmetad.service
echo DEVS="/dev/vdb" > /etc/sysconfig/docker-storage-setup
echo VG="docker" >> /etc/sysconfig/docker-storage-setup
docker-storage-setup
systemctl enable docker 
systemctl start docker

# get atomic host metadata

git clone https://pagure.io/fedora-atomic.git
cd fedora-atomic
git checkout f23
cd ..

git clone https://github.com/CentOS/sig-atomic-buildscripts.git

# get kickstarts

git clone https://git.fedorahosted.org/git/spin-kickstarts.git
cd spin-kickstarts
git checkout f23
cd ..

# initialize ostree repo

mkdir -p /srv/repo
ostree --repo=/srv/repo init --mode=archive-z2

# create a build dir

mkdir build
cd build
ln -s /srv/repo/ repo
cd ..

# chown all this stuff to vagrant user

chown -R vagrant:vagrant *
SCRIPT

  config.vm.provision "shell", inline: $script

end
