# kubernetes/portworx/gke/tensorflow-inception
this is a flowchart for running tensorflow inception model in portworx environment.

# prerequisites
make sure your cluster is setup to run portworx as described
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
$ ./pxctl volume create --shared --size 30 pwx-vol-1
Shared volume successfully created: 539966017538978112
```
volume info can be accessed as follows
```bash
$ ./pxctl volume list
ID			NAME		SIZE	HA	SHARED	ENCRYPTED	IO_PRIORITY	SCALE	STATUS
539966017538978112	pwx-vol-1	30 GiB	1	yes	no		LOW		1	up - detached
```
now we have a 30GiB shared portworx volume that we can mount onto a container

# test on ubuntu container
```bash
$ sudo docker run -v pwx-vol-1:/data -it ubuntu bash
Unable to find image 'ubuntu:latest' locally
latest: Pulling from library/ubuntu
8f7c85c2269a: Pull complete
9e72e494a6dd: Pull complete
3009ec50c887: Pull complete
9d5ffccbec91: Pull complete
e872a2642ce1: Pull complete
Digest: sha256:8f92374f93daa2a8348732d1c3aac06c3a93731eea049cc97a5b2d18c5d1ffd4
Status: Downloaded newer image for ubuntu:latest
```
data folder inside the container now points to portworx volume.

# download imagenet data
download manually
```bash
$ mkdir ${HOME}/tf/images
$ cd ${HOME}/tf/images
$ wget http://image-net.org/imagenet_data/urls/imagenet_fall11_urls.tgz
$ tar -zxvf imagenet_fall11_urls.tgz
$ for d in `cat fall11_urls.txt | grep flickr | head -n 10 | awk '{print $2}'`; do wget $d; done
$ ls -la
total 1451416
drwxrwxr-x  2 1002 1003       4096 Jan 16 17:44 .
drwxr-xr-x 36 root root       4096 Jan 16 17:45 ..
-rw-rw-r--  1 1002 1003     131822 May  3  2006 139488995_bd06578562.jpg
-rw-rw-r--  1 1002 1003     168869 Mar  1  2008 2300491905_5272f77e56.jpg
-rw-rw-r--  1 1002 1003     251625 Jul 11  2008 2658605078_f409b25597.jpg
-rw-rw-r--  1 1002 1003      78483 Aug  6  2008 2737866473_7958dc8760.jpg
-rw-rw-r--  1 1002 1003     145113 Aug 30  2008 2809605169_8efe2b8f27.jpg
-rw-rw-r--  1 1002 1003      94671 Sep 21  2008 2875184020_9944005d0d.jpg
-rw-rw-r--  1 1002 1003      13188 Oct 20  2008 2960028736_74d31b947d.jpg
-rw-rw-r--  1 1002 1003     108058 Jan 15  2009 3198142470_6eb0be5f32.jpg
-rw-rw-r--  1 1002 1003      99322 Oct 27  2009 4051378654_238ca94313.jpg
-rw-rw-r--  1 1002 1003     141193 Nov 11  2009 4094333885_e8462a8338.jpg
-rw-r--r--  1 1002 1003 1134662781 Oct 17  2011 fall11_urls.txt
-rw-rw-r--  1 1002 1003  350302759 Oct 17  2011 imagenet_fall11_urls.tgz
```

or you could run following kubernetes job that will download 100 images onto the shared volume
```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: download-imagenet-data
  labels:
    app: download-imagenet-data
spec:
  parallelism: 1
  template:
    spec:
      containers:
      - name: token-client-test
        image: sdeoras/download-imagenet-data:1.0.0
        imagePullPolicy: Always
        command: ["/imagenet-bin/download.sh", "/tf", "100"]
        volumeMounts:
        - mountPath: /tf
          name: pwx-vol-1
      volumes:
      - name: pwx-vol-1
        # This Portworx volume must already exist.
        portworxVolume:
          volumeID: "pwx-vol-1"
      restartPolicy: Never
```

# execute inception model
```bash
$ sudo docker run -v pwx-vol-1:/tf/images sdeoras/inception:1.1.0 tensorflow/client /tf/images
```
```javascript
{"filename":"139488995_bd06578562.jpg","label":"platypus","conf":40,"labels":[{"label":"platypus","probability":0.40253642},{"label":"stingray","probability":0.2255683},{"label":"gar","probability":0.084772564},{"label":"electric ray","probability":0.051301956},{"label":"tiger shark","probability":0.04534356}]}
{"filename":"2300491905_5272f77e56.jpg","label":"sea slug","conf":62,"labels":[{"label":"sea slug","probability":0.622706},{"label":"flatworm","probability":0.1642618},{"label":"chiton","probability":0.07326072},{"label":"puffer","probability":0.021616828},{"label":"sea cucumber","probability":0.021331556}]}
{"filename":"2658605078_f409b25597.jpg","label":"coral fungus","conf":47,"labels":[{"label":"coral fungus","probability":0.47743613},{"label":"coral reef","probability":0.27731857},{"label":"starfish","probability":0.076814294},{"label":"king crab","probability":0.054524004},{"label":"stinkhorn","probability":0.0451804}]}
{"filename":"2737866473_7958dc8760.jpg","label":"ice lolly","conf":8,"labels":[{"label":"ice lolly","probability":0.08763226},{"label":"pajama","probability":0.075537756},{"label":"Band Aid","probability":0.06951103},{"label":"diaper","probability":0.056206107},{"label":"neck brace","probability":0.04553073}]}
{"filename":"2809605169_8efe2b8f27.jpg","label":"Egyptian cat","conf":22,"labels":[{"label":"Egyptian cat","probability":0.22902574},{"label":"tabby","probability":0.10516237},{"label":"black-footed ferret","probability":0.06931393},{"label":"hare","probability":0.063545406},{"label":"tiger cat","probability":0.04854316}]}
{"filename":"2875184020_9944005d0d.jpg","label":"English springer","conf":35,"labels":[{"label":"English springer","probability":0.3564009},{"label":"Shih-Tzu","probability":0.18038401},{"label":"Shetland sheepdog","probability":0.080071025},{"label":"miniature schnauzer","probability":0.054970328},{"label":"hamster","probability":0.040101986}]}
{"filename":"2960028736_74d31b947d.jpg","label":"dugong","conf":36,"labels":[{"label":"dugong","probability":0.36984172},{"label":"brain coral","probability":0.23023993},{"label":"coral reef","probability":0.139403},{"label":"electric ray","probability":0.07686534},{"label":"loggerhead","probability":0.06790047}]}
{"filename":"3198142470_6eb0be5f32.jpg","label":"howler monkey","conf":27,"labels":[{"label":"howler monkey","probability":0.27375326},{"label":"titi","probability":0.19222338},{"label":"orangutan","probability":0.16780578},{"label":"macaque","probability":0.08841917},{"label":"patas","probability":0.05597403}]}
{"filename":"4051378654_238ca94313.jpg","label":"junco","conf":19,"labels":[{"label":"junco","probability":0.19585285},{"label":"bulbul","probability":0.17316884},{"label":"water ouzel","probability":0.1555251},{"label":"robin","probability":0.15277754},{"label":"brambling","probability":0.13023143}]}
{"filename":"4094333885_e8462a8338.jpg","label":"orangutan","conf":71,"labels":[{"label":"orangutan","probability":0.7108114},{"label":"chimpanzee","probability":0.07837264},{"label":"gorilla","probability":0.036110267},{"label":"mask","probability":0.02937674},{"label":"miniature pinscher","probability":0.020154843}]}
```
More info on TF model is [here](https://github.com/sdeoras/tensorflow/tree/master/inception5h)

