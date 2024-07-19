# apps
#echo "set -g mouse" > /home/vagrant/.tmux.conf

INSTALL_MINIKUBE="true"
INSTALL_SAMBA="false"
MINIKUBE_VERSION="v1.23.2"
K9S_VERSION="v0.24.9"
HELM_VERSION="v3.7.1"
K8S_VERSION="v1.22.4"
KUBECTL_VERSION="1.21.1-00"

ENABLE_SSH_SERVER="true"

# SSH SERVER
if [[ ${ENABLE_SSH_SERVER} == "true" ]];then
  echo "Enabling ssh remote access"
  sudo sed -i "s/PasswordAuthentication no/#PasswordAuthentication no/" /etc/ssh/sshd_config
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
sudo apt-get install -y docker-ce
sudo usermod -aG docker vagrant


# Kubernetes
sudo apt-get update && sudo apt-get install -y apt-transport-https
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubectl=${KUBECTL_VERSION}


# Minikube
curl -Lo minikube https://storage.googleapis.com/minikube/releases/${MINIKUBE_VERSION}/minikube-linux-amd64 > /dev/null 2>&1
chmod +x minikube
sudo cp minikube /usr/local/bin && rm minikube


# Helm
curl -s https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz|tar zx
sudo cp linux-amd64/helm /usr/local/bin

# Docker compose
curl -L "https://github.com/docker/compose/releases/download/1.23.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose


# k9s
curl -SL  https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_Linux_x86_64.tar.gz |tar zxv -C /tmp
sudo cp /tmp/k9s /usr/local/bin


# Clone repo from kubernets course
#runuser -l vagrant -c "mkdir -p /home/vagrant/curso;cd /home/vagrant/curso;git clone https://github.com/LevelUpEducation/kubernetes-demo.git"

# Install and start minikube --------------------------------------------------------------
if [[ "$INSTALL_MINIKUBE" == "true" ]]; then
  sudo -i minikube start --vm-driver=none --kubernetes-version=${K8S_VERSION}
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
