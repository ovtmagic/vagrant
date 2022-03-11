#!/bin/bash


# Extra packages
sudo apt-get update
sudo apt-get -y install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg2 \
    make \
    python \
    software-properties-common \
    socat \
    git \
    aptitude \
    jq

# k9s
echo "***********************************"
echo "* Installing k9s"
echo "***********************************"
curl -SL  https://github.com/derailed/k9s/releases/download/v0.25.18/k9s_Linux_x86_64.tar.gz |tar zxv -C /tmp
sudo cp /tmp/k9s /usr/local/bin

# Helm
echo "***********************************"
echo "* Installing Helm"
echo "***********************************"
#curl -s https://storage.googleapis.com/kubernetes-helm/helm-v2.16.1-linux-amd64.tar.gz|tar zx
curl -s https://get.helm.sh/helm-v3.4.2-linux-amd64.tar.gz|tar zx
sudo cp linux-amd64/helm /usr/local/bin

# add to docker group
sudo usermod -aG docker vagrant

# User configuration
USERHOME=/home/vagrant
echo "alias k=kubectl" >> $USERHOME/.bashrc
echo "complete -o default -F __start_kubectl k" >> $USERHOME/.bashrc
echo "export do=\"--dry-run=client -o yaml\" " >> $USERHOME/.bashrc
echo "export now=\"--force --grace-period=0\" " >> $USERHOME/.bashrc
echo "HOME=${HOME}"
