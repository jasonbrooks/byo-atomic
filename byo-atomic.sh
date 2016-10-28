#!/bin/bash

# working dir

working_dir="/home/fedora/working"

# what's your base distro and version

base_distro="fedora"
distro_version="f25"

#base_distro="centos"
#distro_version="downstream"

setup() {
if [ $base_distro = "centos" ]; then
  metadata_repo="https://github.com/CentOS/sig-atomic-buildscripts.git"
elif [ $base_distro = "fedora" ]; then
  metadata_repo="https://pagure.io/fedora-atomic.git"
fi

if [ $base_distro = "centos" ]; then
  kickstart_repo="https://github.com/CentOS/sig-atomic-buildscripts.git"
elif [ $base_distro = "fedora" ]; then
  kickstart_repo="https://pagure.io/fedora-kickstarts.git"
fi

# install updates and needed packages

dnf update -y
sudo dnf copr enable -y jasonbrooks/rpm-ostree-toolbox
dnf install -y git docker polipo rpm-ostree-toolbox libvirt createrepo
dnf update -y imagefactory* --enablerepo=updates-testing

# turn on polipo & libvirt

systemctl enable polipo
systemctl start polipo
systemctl enable libvirtd
systemctl start libvirtd
systemctl start virtlogd 

# set up for docker

systemctl start lvm2-lvmetad.service
echo DEVS="/dev/vdb" > /etc/sysconfig/docker-storage-setup
echo VG="docker" >> /etc/sysconfig/docker-storage-setup
docker-storage-setup
systemctl enable docker --now

mkdir -p $working_dir
cd $working_dir

# get atomic host metadata and kickstarts

git clone -b $distro_version $metadata_repo metadata
git clone -b $distro_version $kickstart_repo kickstarts

# modify tdl to use local installer tree

sed -i 's#http://.*#http://192.168.122.1:8000/installer/images/</url>#g' metadata/*.tdl

# modify kickstarts to use local ostree repo

sed -i 's#--url=.* #--url=http://192.168.122.1:8000/repo/ #g' kickstarts/*atomic*.ks

# fedora config.ini needs a tweak

if [ $base_distro = "fedora" ]; then
  sed -i "s#^release.*#release     = ${distro_version}#g" metadata/config.ini
  sed -i "s#%(release)s#${distro_version:1}#g" metadata/config.ini
fi

# initialize ostree repo

mkdir -p /srv/repo
ostree --repo=/srv/repo init --mode=archive-z2

# mirror centos repo
echo $base_distro
if [ $base_distro = "centos" ]; then
  ostree remote add --repo=/srv/repo centos-atomic-host --set=gpg-verify=false http://mirror.centos.org/centos/7/atomic/x86_64/repo && ostree pull --depth=0 --repo=/srv/repo --mirror centos-atomic-host centos-atomic-host/7/x86_64/standard
elif [ $base_distro = "fedora" ]; then
  ostree remote add --repo=/srv/repo fedora-atomic --set=gpg-verify=false https://dl.fedoraproject.org/pub/fedora/linux/atomic/${distro_version:1}/ && ostree pull --depth=0 --repo=/srv/repo --mirror fedora-atomic fedora-atomic/${distro_version:1}/x86_64/docker-host
fi

# create a build dir

mkdir build
cd build
ln -s /srv/repo/ repo
cd ..

# SimpleHTTPServer to host local bits
# (from https://gist.github.com/funzoneq/737cd5316e525c388d51877fb7f542de)

cat <<EOF >/etc/systemd/system/simplehttp.service
[Unit]
Description=Job that runs the python SimpleHTTPServer daemon
Documentation=man:SimpleHTTPServer(1)

[Service]
Type=simple
WorkingDirectory=${working_dir}/build
ExecStart=/usr/bin/python -m SimpleHTTPServer 8000 &
ExecStop=/bin/kill `/bin/ps aux | /bin/grep SimpleHTTPServer | /bin/grep -v grep | /usr/bin/awk '{ print $2 }'`
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

systemctl enable simplehttp --now
}

tree() {
echo "composing tree"
sudo rpm-ostree compose tree --repo=/srv/repo --proxy=http://127.0.0.1:8123 ${working_dir}/metadata/*-host.json
}

installer() {
echo "building installer"
sudo rpm-ostree-toolbox installer --overwrite --ostreerepo ${working_dir}/build/repo -c ${working_dir}/metadata/config.ini -o ${working_dir}/build/installer
}

images() {
sudo rpm-ostree-toolbox imagefactory --overwrite --tdl ${working_dir}/metadata/*.tdl -c  ${working_dir}/metadata/config.ini -i kvm -k ${working_dir}/kickstarts/*-atomic.ks -i vagrant-libvirt -i vagrant-virtualbox --vkickstart ${working_dir}/kickstarts/*atomic*vagrant.ks --ostreerepo ${working_dir}/build/repo -o ${working_dir}/build/virt
}
"$@"
