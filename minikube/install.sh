# apps
#echo "set -g mouse" > /home/vagrant/.tmux.conf

INSTALL_MINIKUBE="true"
INSTALL_SAMBA="false"
#MINIKUBE_VERSION="latest"
MINIKUBE_VERSION="v1.30.0"
K9S_VERSION="v0.31.9"
HELM_VERSION="v3.18.2"
K8S_VERSION="v1.27.0-rc.0"
KUBECTL_VERSION="v1.33.1"
DOCKER_VERSION="5:27.3.1-1~ubuntu.22.04~jammy"

ENABLE_SSH_SERVER="true"

# SSH SERVER
if [[ ${ENABLE_SSH_SERVER} == "true" ]];then
  echo "Enabling ssh remote access"
  #sudo sed -i "s/PasswordAuthentication no/#PasswordAuthentication no/" /etc/ssh/sshd_config
  sudo echo "PasswordAuthentication yes" > /etc/ssh/sshd_config.d/60-cloudimg-settings.conf
  systemctl restart sshd
fi

# Docker
sudo apt-get update
sudo apt-get -y install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg2 \
    make \
    python \
    software-properties-common \
    jq \
    unzip
apt-get install -y aptitude git socat conntrack
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo apt-key fingerprint 0EBFCD88
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
sudo apt-get -y update
# apt-cache madison docker-ce -> to see versions
sudo apt-get install -y docker-ce=${DOCKER_VERSION}
sudo usermod -aG docker vagrant


# Kubernetes
sudo apt-get update && sudo apt-get install -y apt-transport-https
curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
sudo install kubectl /usr/local/bin/kubectl
rm kubectl


# Minikube
curl -LO https://storage.googleapis.com/minikube/releases/${MINIKUBE_VERSION}/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
rm minikube-linux-amd64


# Helm
curl -s https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz|tar zx
sudo cp linux-amd64/helm /usr/local/bin

# Docker compose
curl -L "https://github.com/docker/compose/releases/download/1.23.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose


# k9s
curl -SL  https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_Linux_amd64.tar.gz |tar zxv -C /tmp
sudo cp /tmp/k9s /usr/local/bin

# crictl
curl -SL https://github.com/kubernetes-sigs/cri-tools/releases/download/v1.33.0/crictl-v1.33.0-linux-amd64.tar.gz | tar zxv -C /tmp
sudo cp /tmp/crictl /usr/local/bin

# cri-dockerd
curl -LO  https://github.com/Mirantis/cri-dockerd/releases/download/v0.3.20/cri-dockerd_0.3.20.3-0.ubuntu-jammy_amd64.deb
sudo apt install -y ./cri-dockerd_0.3.20.3-0.ubuntu-jammy_amd64.deb
rm cri-dockerd_0.3.20.3-0.ubuntu-jammy_amd64.deb

# Clone repo from kubernets course
#runuser -l vagrant -c "mkdir -p /home/vagrant/curso;cd /home/vagrant/curso;git clone https://github.com/LevelUpEducation/kubernetes-demo.git"

# Install and start minikube --------------------------------------------------------------
if [[ "$INSTALL_MINIKUBE" == "true" ]]; then
  sudo -i minikube start --vm-driver=none --kubernetes-version=${K8S_VERSION} --force
  #sudo -i helm init --stable-repo-url https://charts.helm.sh/stable 
  sudo minikube addons enable metrics-server
fi


# Install Samba
if [[ "$INSTALL_SAMBA" == "true" ]]; then
  sudo apt-get -y install samba
  cat /vagrant/smb.conf >> /etc/samba/smb.conf
fi

# Install AWS
if [[ "$INSTALL_AWS" = "false" ]]; then
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  unzip awscliv2.zip
  sudo ./aws/install
fi

# User configuration
echo "Copy .kube/config file"
mkdir -p /home/vagrant/.kube
sudo -i kubectl config view --flatten > /home/vagrant/.kube/config
sudo chown -R vagrant:vagrant /home/vagrant/.kube

echo 'PATH=$PATH:/home/vagrant/bin' >> /home/vagrant/.bashrc
echo "source <(kubectl completion bash)" >> /home/vagrant/.bashrc
echo "source <(helm completion bash)" >> /home/vagrant/.bashrc

echo "alias k=kubectl" >> /home/vagrant/.bashrc
echo "complete -o default -F __start_kubectl k" >> /home/vagrant/.bashrc
echo "export do=\"--dry-run=client -o yaml\" " >> /home/vagrant/.bashrc
echo "export now=\"--force --grace-period=0\" " >> /home/vagrant/.bashrc

echo "--- Configuration End ---"
