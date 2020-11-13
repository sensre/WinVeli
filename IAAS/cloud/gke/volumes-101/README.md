# kubernetes/portworx/gke/volumes-101
make sure your cluster is setup to run portworx as described in
[here](https://github.com/sdeoras/kubernetes/tree/master/portworx/gke/setup-101)

# ssh onto node
```bash
$ node=`gcloud compute instances list | grep "pwx-cluster-1" | head -n 1 | awk '{print $1}'`
$ gcloud compute ssh ${node}
```
once you are logged on access `pxctl` CLI
```bash
$ cd /opt/pwx/bin
$ ./pxctl status
Status: PX is operational
License: Trial (expires in 30 days)
Node ID: gke-pwx-cluster-1-default-pool-ad22f238-2c9v
	IP: 10.138.0.4
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
	IP		ID						StorageNode	UseCapacity	Status
	10.138.0.5	gke-pwx-cluster-1-default-pool-ad22f238-xvw3	Yes		2.0 GiB	10 GiB		Online
	10.138.0.6	gke-pwx-cluster-1-default-pool-ad22f238-2s1b	Yes		2.0 GiB	10 GiB		Online
	10.138.0.4	gke-pwx-cluster-1-default-pool-ad22f238-2c9v	Yes		2.0 GiB	10 GiB		Online	 (This node)
Global Storage Pool
	Total Used    	:  6.1 GiB
	Total Capacity	:  30 GiB
```

this shows that there is a global pool of 30GiB storage capacity

# create volumes
```bash
$ ./pxctl volume create --shared --size 5 pwx-shared-vol
Shared volume successfully created: 271151765769525900
```
volume info can be accessed as follows
```bash
$ ./pxctl volume list
ID			NAME		SIZE	HA	SHARED	ENCRYPTED	IO_PRIORITY	SCALE	STATUS
271151765769525900	pwx-shared-vol	5 GiB	1	yes	no		LOW		1	up - detached
```
this being a shared volume can now also be accessed from any other node in the cluster

# mount volume on host (not container)
volume can be mounted on a host to a target folder. there are three steps
* create a folder on host machine
* `attach` the volume on host
* `mount` the volume on host

```bash
$ sudo mkdir /tmp/data
$ ./pxctl host attach pwx-shared-vol
Volume successfully attached at: /dev/pxd/pxd271151765769525900
$ ./pxctl host mount pwx-shared-vol /mnt/data
mount: Mountpath  (/mnt/data) is not a shared mount between host and PX container<Paste>
```
so that did not work. let's create non-shared volume

# non-shared volume
```bash
$ ./pxctl volume create pwx-vol-1 --size 5
Volume successfully created: 651225751947963105
```
now attach and mount this volume
```bash
$ ./pxctl host attach pwx-vol-1
Volume successfully attached at: /dev/pxd/pxd651225751947963105
$ ./pxctl host mount pwx-vol-1 /mnt/data
mount: Mountpath  (/mnt/data) is not a shared mount between host and PX container
```
so that did not work as well!!


