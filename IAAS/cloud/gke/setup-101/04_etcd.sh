#!/usr/bin/env bash
node=`kubectl get nodes | grep "^gke" | head -n 1 | awk '{print $1}'`
export IP=$(gcloud compute ssh ${node} -- hostname -I | awk '{print $1}')

gcloud compute ssh ${node} -- sudo docker run -d --net=host -p 4001:2379 --volume=/var/lib/px-etcd:/etcd/data --name etcd quay.io/coreos/etcd /usr/local/bin/etcd --data-dir=/etcd-data --name node1 --advertise-client-urls http://${IP}:4001 --listen-client-urls http://${IP}:4001 --initial-advertise-peer-urls http://${IP}:2380 --listen-peer-urls http://${IP}:2380 --initial-cluster node1=http://${IP}:2380
echo ${node}

echo "Checking if etcd is reachable from every node in cluster"
for d in `kubectl get nodes | grep "^gke" | awk '{print $1}'`; do
	gcloud compute ssh ${d} -- curl http://${node}:4001/version
	gcloud compute ssh ${d} --  '(echo export PATH=\"\${PATH}:/opt/pwx/bin\" >> .bashrc)'
done

sed -e "s/etcd-node-addr/${node}/g" px-spec.yaml > /tmp/px-spec.yaml
