#!/bin/bash
project=`gcloud config list | grep ^project | awk '{print $3}'`
zone=`gcloud config list | grep ^zone | awk '{print $3}'`
account=`gcloud config list | grep ^account | awk '{print $3}'`
gcloud container clusters get-credentials pwx-cluster-1 --zone ${zone} --project ${project}
kubectl get nodes
kubectl create clusterrolebinding myname-cluster-admin-binding --clusterrole=cluster-admin --user=${account}
