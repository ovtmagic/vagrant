#!/bin/bash

# Create K8s cluster: master node
echo "***********************************"
echo "* Creating K8s cluster packages"
echo "***********************************"
sudo bash -c "echo '192.168.50.100 k8smaster' >> /etc/hosts"
sudo -i kubeadm init --config=/vagrant/k8sconfig/kubeadm-config.yaml --upload-certs | tee kubeadm-init.out
#sudo -i kubeadm init --config=/vagrant/k8sconfig/kubeadm-config.yaml --apiserver-advertise-address 192.168.50.100 --upload-certs | tee kubeadm-init.out

# non root user configuration to start using cluster
echo "***********************************"
echo "* User configuration"
echo "***********************************"
USERHOME=/home/vagrant
mkdir -p $USERHOME/.kube
sudo cp /etc/kubernetes/admin.conf $USERHOME/.kube/config
# copy also to root home
mkdir -p $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config 
sudo chown -R $(id vagrant -u):$(id vagrant -g) $USERHOME/.kube
#sudo chown $(id -u):$(id -g) $USERHOME/.kube/config
kubectl apply -f /vagrant/k8sconfig/calico.yaml
# add to docker group
sudo usermod -aG docker vagrant

# kubectl
sudo apt-get install bash-completion -y
source <(kubectl completion bash)

echo "source <(kubectl completion bash)" >> $USERHOME/.bashrc
echo "alias k=kubectl" >> $USERHOME/.bashrc
echo "complete -o default -F __start_kubectl k" >> $USERHOME/.bashrc
echo "export do=\"--dry-run=client -o yaml\" " >> $USERHOME/.bashrc
echo "export now=\"--force --grace-period=0\" " >> $USERHOME/.bashrc


# Token for the worker
echo "***********************************"
echo "* K8s token and certificate"
echo "***********************************"
sudo kubeadm token list |grep kubeadm:default-node-token|awk '{print $1; }' > /vagrant/k8s_token
openssl x509 -pubkey \
-in /etc/kubernetes/pki/ca.crt | openssl rsa \
-pubin -outform der 2>/dev/null | openssl dgst \
-sha256 -hex | sed 's/ˆ.* //' > /vagrant/k8s_cert

# Taint (only for training environment): allow non-infrastructure pods:
kubectl taint nodes --all node-role.kubernetes.io/master-
kubectl taint nodes --all node.kubernetes.io/not-ready-

# k9s
echo "***********************************"
echo "* Installing k9s"
echo "***********************************"
curl -SL  https://github.com/derailed/k9s/releases/download/v0.17.1/k9s_Linux_x86_64.tar.gz |tar zxv -C /tmp
sudo cp /tmp/k9s /usr/local/bin

# Helm
#curl -s https://storage.googleapis.com/kubernetes-helm/helm-v2.16.1-linux-amd64.tar.gz|tar zx
curl -s https://get.helm.sh/helm-v3.4.2-linux-amd64.tar.gz|tar zx
sudo cp linux-amd64/helm /usr/local/bin
#sudo cp linux-amd64/tiller /usr/local/bin

# Metrics Server (commit b3d6a54)
# git clone https://github.com/kubernetes-sigs/metrics-server.git
# cd metrics-server
# git checkout b3d6a54
# helm install --set 'args={--kubelet-insecure-tls}' --namespace kube-system metrics charts/metrics-server