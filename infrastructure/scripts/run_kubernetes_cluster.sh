#/bin/bash

#####################################################
######################USAGE##########################
# bash script.sh \
# -mfn "terraform output -json | jq -r '.masters_ips.value.internal[][]' | head -n 1" \
# -mons "terraform output -json | jq -r '.masters_ips.value.internal[][]' | tail -n +2" \
# -wnd "terraform output -json | jq -r '.workers_ips.value.internal[][]'"
#####################################################

POD_NETWORK="10.244.0.0/16"
CONTROL_PLANE_ENDPOINT="192.168.10.45:8443"

while [ -n "$1" ]; do
case "$1" in
-mfn) MASTER_FIRST_NODE="$($2)"
      shift;;
-mons) MASTERS_OTHER_NODES="$($2)"
       shift;;
-wnd) WORKERS_NODES="$($2)"
      shift;;
*) echo "$1 is not a option";;
esac; shift; done

ssh $MASTER_FIRST_NODE "sudo kubeadm init --cri-socket unix:///var/run/cri-dockerd.sock --pod-network-cidr=$POD_NETWORK --control-plane-endpoint $CONTROL_PLANE_ENDPOINT --upload-certs" &&

KUBEADM_TOKEN=$(ssh $MASTER_FIRST_NODE "sudo kubeadm token create --print-join-command")
KUBEADM_CERTS=$(ssh $MASTER_FIRST_NODE "sudo kubeadm init phase upload-certs --upload-certs | grep -vw -e certificate -e Namespace")

for host in $MASTERS_OTHER_NODES; do
    ssh $host "sudo $KUBEADM_TOKEN --control-plane --certificate-key $KUBEADM_CERTS --cri-socket unix:///var/run/cri-dockerd.sock"
done

for host in $WORKERS_NODES; do
    ssh $host "sudo $KUBEADM_TOKEN --cri-socket unix:///var/run/cri-dockerd.sock"
done
