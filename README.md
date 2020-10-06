## COMMAND

ansible-playbook -i inventoryPath setIp.yml
ansible-playbook -i inventoryPath lab.yml
ansible-playbook -i inventoryKubeClusterPath --become --become-user=root subProject/kubespray/cluster.yml
### to use kubectl
export KUBECONFIG=/etc/kubernetes/kubelet.conf


## TODO
### ORDER
##### TODO update (certin update to get vuln)

1. fixedIP (not perfect) (WIN ok, CENTOS ok, ubuntu TODO)
2. setupFirewall (rule all to all)(only pfsense) (TODO port forwarding) // TODO https://www.sophos.com/fr-fr/products/free-tools/sophos-utm-home-edition.aspx fortinet
update (TODO)
3. Domain (dns), join, users, (add dns for ip TODO)
4. PKI (only windows, add standalone, TODO openssl (non windows host)), GPO deploiement root certr
ISSI etc ... (TODO)
5. Service 1er niveau (docker, kubernetes (TODO use PKI certificate)) (pas dessuite)
6. Create directory structure, upload file (linux TODO)
7. File share, (smb(win_share), dfs) TODO
8. GPO, TODO (here to get the file share (necessary ?))
9. tools
    * ELK
    * SIEM
    * monitoring
    *  wazuh
    * ...
10. ... ? 
11. firewall production rule