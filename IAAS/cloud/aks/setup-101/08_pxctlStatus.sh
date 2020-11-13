#!/usr/bin/env bash
for d in `kubectl get nodes | grep "^gke" | awk '{print $1}'`; do
	gcloud compute ssh ${d} --  '(/opt/pwx/bin/pxctl status)'
done
