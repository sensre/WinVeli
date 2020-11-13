#!/bin/bash
zone=`gcloud config list | grep ^zone | awk '{print $3}'`
gcloud container clusters resize pwx-cluster-1 --size=10 --zone=${zone}
