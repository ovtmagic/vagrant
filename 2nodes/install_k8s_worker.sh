#!/bin/bash

# kubelet configuration
echo "***********************************"
echo "* Joining worker"
echo "***********************************"
kubelet_file="/etc/systemd/system/kubelet.service.d/10-kubeadm.conf"
sed -i "s/kubelet /kubelet --node-ip=192.168.50.101 /" $kubelet_file
systemctl daemon-reload

# Joining worker
echo "***********************************"
echo "* Joining worker"
echo "***********************************"
grep -q k8smaster /etc/hosts || sudo bash -c "echo '192.168.50.100 k8smaster' >> /etc/hosts"
systemctl restart kubelet

k8s_token=$(cat /vagrant/k8s_token)
k8s_cert=$(cat /vagrant/k8s_cert|awk '{ print $2; }')
sudo -i kubeadm join \
    --token ${k8s_token} \
    k8smaster:6443 \
    --discovery-token-ca-cert-hash \
    sha256:${k8s_cert} --apiserver-advertise-address  192.168.50.101
