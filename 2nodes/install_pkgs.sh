#!/bin/bash

k8s_version="1.21.1-00"
#k8s_version="1.20.0-00"
# Update and install packages
echo "***********************************"
echo "* Installing packages              "
echo "***********************************"
sudo bash -c "echo 'deb  http://apt.kubernetes.io/  kubernetes-xenial  main' > /etc/apt/sources.list.d/kubernetes.list"
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
sudo apt-get update
sudo apt-get install -y kubeadm=${k8s_version} kubelet=${k8s_version} kubectl=${k8s_version}
sudo apt-get install -y docker.io
sudo apt-mark hold kubelet kubeadm kubectl

# Extra packages
sudo apt-get -y install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg2 \
    make \
    python \
    software-properties-common
apt-get install -y aptitude git socat
