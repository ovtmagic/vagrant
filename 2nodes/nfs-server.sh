#!/bin/bash

sudo apt-get update
sudo apt-get install -y nfs-kernel-server nfs-common
sudo mkdir /opt/sfw
sudo chmod 1777 /opt/sfw
sudo bash -c 'echo hello > /opt/sfw/hello.txt'
sudo bash -c  'echo "/opt/sfw/ *(rw,sync,no_root_squash,subtree_check)" >> /etc/exports'
sudo exportfs -ra

sudo showmount -e k8smaster
