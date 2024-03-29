#!/bin/bash
#/* **************** LFS260:2021-08-10 s_04/k8scp.sh **************** */
#/*
# * The code herein is: Copyright the Linux Foundation, 2021
# *
# * This Copyright is retained for the purpose of protecting free
# * redistribution of source.
# *
# *     URL:    https://training.linuxfoundation.org
# *     email:  info@linuxfoundation.org
# *
# * This code is distributed under Version 2 of the GNU General Public
# * License, which you should have received with the source.
# *
# */
#!/bin/bash -x
## TxS 6-2021 
## v1.21.1 CKA/CKAD/CKS
echo "This script is written to work with Ubuntu 18.04"
sleep 3
echo
echo "Disable swap until next reboot"
echo 
sudo swapoff -a

echo "Update the local node"
sudo apt-get update && sudo apt-get upgrade -y
echo
echo "Install Docker"
sleep 3

sudo apt-get install -y docker.io
echo
echo "Install kubeadm, kubelet, and kubectl"
sleep 3

sudo sh -c "echo 'deb http://apt.kubernetes.io/ kubernetes-xenial main' >> /etc/apt/sources.list.d/kubernetes.list"

sudo sh -c "curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -"

sudo apt-get update

sudo apt-get install -y kubeadm=1.21.1-00 kubelet=1.21.1-00 kubectl=1.21.1-00

sudo apt-mark hold kubelet kubeadm kubectl

echo
echo "Installed - now to get Calico Project network plugin"

## If you are going to use a different plugin you'll want
## to use a different IP address, found in that plugins 
## readme file. 

sleep 3

## This assumes you are not using 192.168.0.0/16 for your host
sudo kubeadm init --kubernetes-version 1.21.1 --pod-network-cidr 10.10.0.0/16 --apiserver-advertise-address 192.168.50.100

sleep 5

echo "Running the steps explained at the end of the init output for you"

mkdir -p $HOME/.kube

sleep 2

sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config

sleep 2

sudo chown $(id -u):$(id -g) $HOME/.kube/config

echo "Apply Calico network plugin from ProjectCalico.org"
echo "If you see an error they may have updated the yaml file"
echo "Use a browser, navigate to the site and find the updated file"

#kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
kubectl apply -f /vagrant/k8sconfig/calico.yaml

echo
echo
sleep 3
echo "You should see this node in the output below"
echo "It can take up to a minute for node to show Ready status"
echo
kubectl get node
echo

echo
echo "Script finished. Move to the next step"

# Token for the worker
echo
echo "Create files with token and certificates to join worker"
echo "***********************************"
echo "* K8s token and certificate"
echo "***********************************"
sudo kubeadm token list |grep kubeadm:default-node-token|awk '{print $1; }' > /vagrant/k8s_token
openssl x509 -pubkey \
-in /etc/kubernetes/pki/ca.crt | openssl rsa \
-pubin -outform der 2>/dev/null | openssl dgst \
-sha256 -hex | sed 's/ˆ.* //' > /vagrant/k8s_cert

# Remove taints on master
kubectl taint nodes --all node-role.kubernetes.io/master-

# Install kube-bench
curl -L \
https://github.com/aquasecurity/kube-bench/releases/download/v0.3.1/kube-bench_0.3.1_linux_amd64.deb \
-o kube-bench_0.3.1_linux_amd64.deb
sudo apt install ./kube-bench_0.3.1_linux_amd64.deb