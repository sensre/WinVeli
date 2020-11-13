# kubernetes/portworx/gke/setup-101
these are some bash scripts to get up and running with portworx on gke kubernetes cluster.

# prerequisites
* make sure gcloud and kubectl are installed, configured and running
* make sure following commands are have expected output for your account and/or set it up otherwise
```bash
$ gcloud config list | grep ^project | awk '{print $3}'
$ gcloud config list | grep ^zone | awk '{print $3}'
$ gcloud config list | grep ^account | awk '{print $3}'
```
* make sure there are no gke clusters by the name pwx-cluster-1
* make sure there are no disks by the name pwx-disk-1, 2 and 3

# run scripts
run scripts sequentially in order

# create disks
```bash
$ ./00_create_disks.sh
```
you can check if the disks are available as follows
```bash
$ gcloud compute disks list
NAME        ZONE        SIZE_GB  TYPE         STATUS
pwx-disk-1  us-west1-a  10       pd-standard  READY
pwx-disk-2  us-west1-a  10       pd-standard  READY
pwx-disk-3  us-west1-a  10       pd-standard  READY
```

# create cluster
```bash
$ ./01_createCluster.sh
```
this command can take up to a few minutes to complete.
Verify that the cluster is up and running as follows
```bash
$ gcloud container clusters list
NAME           LOCATION    MASTER_VERSION  MASTER_IP       MACHINE_TYPE   NODE_VERSION  NUM_NODES  STATUS
pwx-cluster-1  us-west1-a  1.7.11-gke.1    35.197.104.213  n1-standard-1  1.7.11-gke.1  3          RUNNING
```

# get credentials to the cluster
```bash
$ ./02_getCred.sh
```
this will allow `kubectl` on your machine to talk to the cluster and authorize your account to perform
tasks on behalf of kubernetes master. You should see following text displayed
```text
kubeconfig entry generated for pwx-cluster-1.
clusterrolebinding "myname-cluster-admin-binding" created
```
Now verify kubectl can talk to the cluster
```bash
$ kubectl get nodes
NAME                                           STATUS    ROLES     AGE       VERSION
gke-pwx-cluster-1-default-pool-ad22f238-2c9v   Ready     <none>    4m        v1.7.11-gke.1
gke-pwx-cluster-1-default-pool-ad22f238-2s1b   Ready     <none>    4m        v1.7.11-gke.1
gke-pwx-cluster-1-default-pool-ad22f238-xvw3   Ready     <none>    4m        v1.7.11-gke.1
```

# attach disks
```bash
$ ./03_attachDisks.sh
```
# start etcd service
this section is portworx specific. An `etcd` service is required by the portworx daemons to communicate
with other portworx daemons. Portworx will provide a cluster wide storage pool, hence it is necessary for
each portworx daemon to be aware of other running daemons.
```bash
$ ./04_etcd.sh
```
here is the complete output from this command
```text
Warning: Permanently added 'compute.5315369545424412393' (ECDSA) to the list of known hosts.
Connection to 35.197.79.200 closed.
Unable to find image 'quay.io/coreos/etcd:latest' locally
latest: Pulling from coreos/etcd
ff3a5c916c92: Pull complete
9ba32cd32bb3: Pull complete
4784c1cc8628: Pull complete
841a50506c53: Pull complete
8f16dd24d5ae: Pull complete
c15c14574a0b: Pull complete
Digest: sha256:d5267ef74ef02d2c0ef80ce3f70b50afe621d2e4c121987bd305d326acabb68c
Status: Downloaded newer image for quay.io/coreos/etcd:latest
a860d215f618cd7625485bba6bdbad0c401766e89018365a0ad62d0db6515325
Connection to 35.197.79.200 closed.
gke-pwx-cluster-1-default-pool-ad22f238-2c9v
Checking if etcd is reachable from every node in cluster
{"etcdserver":"3.2.14","etcdcluster":"3.2.0"}Connection to 35.197.79.200 closed.
Connection to 35.197.79.200 closed.
Warning: Permanently added 'compute.3471029160237047529' (ECDSA) to the list of known hosts.
{"etcdserver":"3.2.14","etcdcluster":"3.2.0"}Connection to 35.197.13.212 closed.
Connection to 35.197.13.212 closed.
Warning: Permanently added 'compute.7010875630039572201' (ECDSA) to the list of known hosts.
{"etcdserver":"3.2.14","etcdcluster":"3.2.0"}Connection to 35.185.213.67 closed.
Connection to 35.185.213.67 closed.
```
`etcd` runs as a container on one of the nodes, hence you see that the docker image is first
being pulled. Also the script tries to make sure that `etcd` service is reachable from every other
node in the cluster. This is evident by the version info obtained from each node by querying the `etcd`
service.

# setup pvc controller
this step is also specific to portworx. Portworx requires privilages to manage physical volumes
on behalf of kubernetes master.
```bash
$ ./05_pvcController.sh
```
this spits out following info
```text
serviceaccount "portworx-pvc-controller-account" created
clusterrole "portworx-pvc-controller-role" created
clusterrolebinding "portworx-pvc-controller-role-binding" created
deployment "portworx-pvc-controller" created
```
verify that the pods are up and running
```bash
$ kubectl get pods -n kube-system
```
which should spit out info as follows
```text
NAME                                                      READY     STATUS             RESTARTS   AGE
event-exporter-v0.1.7-1642279337-8vtr0                    2/2       Running            0          20m
fluentd-gcp-v2.0.9-380rl                                  2/2       Running            0          20m
fluentd-gcp-v2.0.9-dpj1m                                  2/2       Running            0          20m
fluentd-gcp-v2.0.9-nlp39                                  2/2       Running            0          20m
heapster-v1.4.3-2945177644-rs35g                          3/3       Running            0          18m
kube-dns-3468831164-13jl5                                 3/3       Running            0          20m
kube-dns-3468831164-2b813                                 3/3       Running            0          20m
kube-dns-autoscaler-244676396-xqv8z                       1/1       Running            0          20m
kube-proxy-gke-pwx-cluster-1-default-pool-ad22f238-2c9v   1/1       Running            0          20m
kube-proxy-gke-pwx-cluster-1-default-pool-ad22f238-2s1b   1/1       Running            0          20m
kube-proxy-gke-pwx-cluster-1-default-pool-ad22f238-xvw3   1/1       Running            0          20m
kubernetes-dashboard-1265873680-n41s8                     1/1       Running            0          20m
l7-default-backend-3623108927-g08tl                       1/1       Running            0          20m
portworx-pvc-controller-948263891-2ffm3                   0/1       ImagePullBackOff   0          3m
portworx-pvc-controller-948263891-h0mcq                   0/1       ImagePullBackOff   0          3m
portworx-pvc-controller-948263891-l62pl                   0/1       ImagePullBackOff   0          3m
```

pl. allow some time for status to show `Running` tag on every pod

# apply portworx spec
```bash
$ ./06_pxSpec.sh
```
this should spit out following info
```text
serviceaccount "portworx-pvc-controller-account" unchanged
clusterrole "portworx-pvc-controller-role" configured
clusterrolebinding "portworx-pvc-controller-role-binding" configured
deployment "portworx-pvc-controller" configured
serviceaccount "px-account" created
clusterrole "node-get-put-list-role" created
clusterrolebinding "node-role-binding" created
service "portworx-service" created
daemonset "portworx" created
```

# check status
all that remains now is to check status and make sure everything is running fine
```bash
$ ./07_status.sh
NAME                                                      READY     STATUS    RESTARTS   AGE
event-exporter-v0.1.7-1642279337-8vtr0                    2/2       Running   0          23m
fluentd-gcp-v2.0.9-380rl                                  2/2       Running   0          23m
fluentd-gcp-v2.0.9-dpj1m                                  2/2       Running   0          23m
fluentd-gcp-v2.0.9-nlp39                                  2/2       Running   0          23m
heapster-v1.4.3-2945177644-rs35g                          3/3       Running   0          21m
kube-dns-3468831164-13jl5                                 3/3       Running   0          23m
kube-dns-3468831164-2b813                                 3/3       Running   0          23m
kube-dns-autoscaler-244676396-xqv8z                       1/1       Running   0          23m
kube-proxy-gke-pwx-cluster-1-default-pool-ad22f238-2c9v   1/1       Running   0          23m
kube-proxy-gke-pwx-cluster-1-default-pool-ad22f238-2s1b   1/1       Running   0          23m
kube-proxy-gke-pwx-cluster-1-default-pool-ad22f238-xvw3   1/1       Running   0          23m
kubernetes-dashboard-1265873680-n41s8                     1/1       Running   0          23m
l7-default-backend-3623108927-g08tl                       1/1       Running   0          23m
portworx-2p4x1                                            1/1       Running   0          1m
portworx-ctmsz                                            1/1       Running   0          1m
portworx-pvc-controller-869779336-sl234                   1/1       Running   0          1m
portworx-pvc-controller-869779336-t4fzq                   1/1       Running   0          1m
portworx-pvc-controller-869779336-t93jn                   1/1       Running   0          1m
portworx-qfbz1                                            1/1       Running   0          1m
```

great! everything is up and running. You just configured portworx on a 3-node cluster with 10GiB disk on
each node to create a common storage pool of 30GiB. Volumes can now be created from this pool and
provisioned for use within containers

# pxctl status
verify that a 30GiB storage pool is available
```bash
$ ./08_pxctlStatus.sh
Status: PX is operational
License: Trial (expires in 30 days)
Node ID: gke-pwx-cluster-1-default-pool-ad22f238-xvw3
	IP: 10.138.0.5
 	Local Storage Pool: 1 pool
	POOL	IO_PRIORITY	RAID_LEVEL	USABLE	USED	STATUS	ZONE	REGION
	0	LOW		raid0		10 GiB	2.0 GiB	Online	default	default
	Local Storage Devices: 1 device
	Device	Path		Media Type		Size		Last-Scan
	0:1	/dev/sdb	STORAGE_MEDIUM_MAGNETIC	10 GiB		16 Jan 18 16:20 UTC
	total			-			10 GiB
Cluster Summary
	Cluster ID: px-demo
	Cluster UUID: e2a191b8-aeed-476b-9368-af2793651b46
	Nodes: 3 node(s) with storage (3 online)
	IP		ID						StorageNode	Used	Capacity	Status
	10.138.0.5	gke-pwx-cluster-1-default-pool-ad22f238-xvw3	Yes		2.0 GiB	10 GiB		Online	 (This node)
	10.138.0.6	gke-pwx-cluster-1-default-pool-ad22f238-2s1b	Yes		0 B	10 GiB		Online
	10.138.0.4	gke-pwx-cluster-1-default-pool-ad22f238-2c9v	Yes		2.0 GiB	10 GiB		Online
Global Storage Pool
	Total Used    	:  4.0 GiB
	Total Capacity	:  30 GiB
Connection to 35.185.213.67 closed.
```

# cleanup
delete cluster and disks
```bash
./cleanup.sh
```
