#!/bin/bash
project=`gcloud config list | grep ^project | awk '{print $3}'`
zone=`gcloud config list | grep ^zone | awk '{print $3}'`
gcloud compute --project=${project} disks create pwx-disk-1 --zone=${zone} --type=pd-standard --size=10GB
gcloud compute --project=${project} disks create pwx-disk-2 --zone=${zone} --type=pd-standard --size=10GB
gcloud compute --project=${project} disks create pwx-disk-3 --zone=${zone} --type=pd-standard --size=10GB

gcloud compute disks list
