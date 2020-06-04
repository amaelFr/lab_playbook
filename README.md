## COMMAND

ansible-playbook -i inventoryPath setIp.yml
ansible-playbook -i inventoryPath lab.yml
ansible-playbook -i inventoryKubeClusterPath --become --become-user=root subProject/kubespray/cluster.yml
### to use kubectl
export KUBECONFIG=/etc/kubernetes/kubelet.conf