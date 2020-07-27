## COMMAND

ansible-playbook -i inventoryPath setIp.yml
ansible-playbook -i inventoryPath lab.yml
ansible-playbook -i inventoryKubeClusterPath --become --become-user=root subProject/kubespray/cluster.yml
### to use kubectl
export KUBECONFIG=/etc/kubernetes/kubelet.conf


## TODO
### ORDER
1. fixedIP (not perfect)
2. setupFirewall (rule all to all)(only pfsense) (TODO port forwarding) // TODO https://www.sophos.com/fr-fr/products/free-tools/sophos-utm-home-edition.aspx fortinet
3. Domain (dns), join, (TODO GPO, users)
4. PKI (only windows, add standalone, TODO openssl (non windows host))
5. File share, TODO (here to deploy gpo next)
6. GPO, TODO (here to get the file share (necessary ?))
7. Service 1er niveau (docker, kubernetes (TODO use PKI certificate))
8. tools
    * ELK
    * SIEM
    * monitoring
    * file share (or 5 for GPO)
    *  wazuh
    * ...
9. ... ? 
10. firewall production rule