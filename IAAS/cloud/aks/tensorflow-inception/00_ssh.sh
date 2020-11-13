#!/bin/bash
node=`gcloud compute instances list | grep "pwx-cluster-1" | head -n 1 | awk '{print $1}'`
gcloud compute ssh ${node}
