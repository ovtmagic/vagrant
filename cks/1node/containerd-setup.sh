#!/bin/bash -x

#
# This script is intended to be run on a single Ubuntu 18.04, 
# 2cpu, 8G node to ensure the gVisor runtime can be used.
# By Tim Serewicz, 06/2021 GPL

# Note there is a lot of software downloaded, which may require
# some troubleshooting if any of the sites updates their code,
# which should be expected. 

# Ensure two modules are loaded after reboot

cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF


# Disable swap if not on a cloud instance - done anyway

sudo swapoff -a


# Load the modules now

sudo modprobe overlay

sudo modprobe br_netfilter


# Update sysctl to load iptables and ipforwarding

cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sudo sysctl --system


# Install some necessary software  

sudo apt-get update && sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common


# Install the Docker keyring

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key --keyring /etc/apt/trusted.gpg.d/docker.gpg add -


# Create a Docker repository

sudo add-apt-repository  "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"



# Install and configure the containerd package

sudo apt-get update && sudo apt-get install -y containerd.io

sudo mkdir -p /etc/containerd

sudo containerd config default | sudo tee /etc/containerd/config.toml



# Verify the file has the appropriate contents

cat /etc/containerd/config.toml



# Restart and check containerd

sudo systemctl restart containerd

sudo systemctl status containerd



# Add the Kubernetes repo

sudo sh -c "echo 'deb http://apt.kubernetes.io/ kubernetes-xenial main' >> /etc/apt/sources.list.d/kubernetes.list"


# Add the GPG key for the new repo

sudo sh -c "curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -"



# Install the Kubernetes packages

sudo apt-get update

sudo apt-get install -y kubeadm=1.21.1-00 kubelet=1.21.1-00 kubectl=1.21.1-00

sudo apt-mark hold kubelet kubeadm kubectl



# Create a cluster using containerd

sudo kubeadm init --kubernetes-version 1.21.1 --cri-socket=/var/run/containerd/containerd.sock --pod-network-cidr 192.168.0.0/16

mkdir -p $HOME/.kube

sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config

sudo chown $(id -u):$(id -g) $HOME/.kube/config



# We'll use Calico for the network plugin

kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml


# Wait for all pods and nodes ready
kubectl -n kube-system wait --for=condition=Ready pod --all --timeout=300s
kubectl -n kube-system wait --for=condition=Ready node --all --timeout=300s

# Make sure all the infrastructure pods are running

kubectl get pod --all-namespaces

kubectl describe pod -l component=kube-apiserver -n kube-system


kubectl get events

# Enable command line completion
source <(kubectl completion bash)

echo "source <(kubectl completion bash)" >> $HOME/.bashrc

# Untaint the control plane, as we only have one node
kubectl taint node --all node-role.kubernetes.io/master-


# Get containerd running, append or create several files.
cat <<EOF | sudo tee /etc/containerd/config.toml
disabled_plugins = ["restart"]
[plugins.linux]
  shim_debug = true
[plugins.cri.containerd.runtimes.runsc]
  runtime_type = "io.containerd.runsc.v1"
EOF

cat <<EOF | sudo tee /etc/crictl.yaml
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///var/run/dockershim.sock
timeout: 10
debug: true
EOF


# Wait for all pods and nodes ready
kubectl -n kube-system wait --for=condition=Ready pod --all --timeout=300s
kubectl -n kube-system wait --for=condition=Ready node --all --timeout=300s

# Ensure containerd starts and 

sudo systemctl restart containerd

kubectl get pod --all-namespaces


# Install and configure crictl

wget https://github.com/kubernetes-sigs/cri-tools/releases/download/v1.21.0/crictl-v1.21.0-linux-amd64.tar.gz

tar zxvf crictl-v1.21.0-linux-amd64.tar.gz

sudo mv crictl /usr/local/bin

cat <<EOF | sudo tee /etc/crictl.yaml
runtime-endpoint: unix:///run/containerd/containerd.sock
EOF

sudo wget https://storage.googleapis.com/gvisor/releases/nightly/latest/containerd-shim-runsc-v1 -O /usr/local/bin/containerd-shim-runsc-v1
sudo chmod +x /usr/local/bin/containerd-shim-runsc-v1

sudo wget https://storage.googleapis.com/gvisor/releases/nightly/latest/runsc -O /usr/local/bin/runsc
sudo chmod +x /usr/local/bin/runsc

# Ready to create the runtimeclass and the gVisor pod

