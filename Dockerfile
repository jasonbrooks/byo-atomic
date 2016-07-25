FROM fedora:24

# install needed packages

RUN dnf install -y rpm-ostree git polipo python; \
    dnf clean all

# create working dir, clone fedora and centos atomic definitions

RUN mkdir -p /home/working; \
    cd /home/working; \
    git clone https://github.com/CentOS/sig-atomic-buildscripts; \
    cd sig-atomic-buildscripts; \
    git checkout downstream; \
    cd ..; \
    git clone https://pagure.io/fedora-atomic.git; \
    cd fedora-atomic; \
    git checkout f24; \
    sed -i 's/\"fedora-24\"/\"fedora-24\", \"fedora-24-updates\"/g' fedora-atomic-docker-host.json; \

# create and initialize repo directory

    mkdir -p /srv/repo && \
    ostree --repo=/srv/repo init --mode=archive-z2

# expose default SimpleHTTPServer port, set working dir

EXPOSE 8000
WORKDIR /home/working

# start web proxy and SimpleHTTPServer

CMD polipo; pushd /srv/repo; python -m SimpleHTTPServer; popd


# Build and run this container with:
# 
# docker build --rm -t $USER/atomicrepo .
# docker run -d -p 8000:8000 --name atomicrepo $USER/atomicrepo
# docker exec -it atomicrepo bash 
# 
# Inside the container, mod tree file as described in Step Three of 
# https://github.com/jasonbrooks/byo-atomic/blob/master/README.md
# 
# Then, compose tree with:
#
# rpm-ostree compose tree  --proxy=http://127.0.0.1:8123  --repo=/srv/repo fedora-atomic/fedora-atomic-docker-host.json
#
# Or, for CentOS, with:
#
# rpm-ostree compose tree  --proxy=http://127.0.0.1:8123  --repo=/srv/repo sig-atomic-buildscripts/centos-atomic-host.json
# 
# When the compose is complete, your tree will be accessible at 
# http://$YOUR_IP:8000/repo
# 
# To configure an Atomic host to receive updates from your build machine, 
# run a pair of commands like the following to add a new "foo" repo definition 
# to your host, and then rebase to that tree:
#
# sudo ostree remote add foo http://$YOUR_IP:8000/repo --no-gpg-verify
#
# sudo rpm-ostree rebase foo:fedora-atomic/f23/x86_64/docker-host
