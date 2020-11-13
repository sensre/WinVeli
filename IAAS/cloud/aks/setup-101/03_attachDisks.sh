#!/bin/bash
x=0
for node in `kubectl get nodes | awk '{print $1}' | grep "^gke"`; do
	x=$((x + 1))
	gcloud compute instances attach-disk --disk pwx-disk-${x} ${node}
done
