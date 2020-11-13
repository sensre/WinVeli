#!/bin/bash
gcloud container clusters delete pwx-cluster-1 --quiet
gcloud compute disks delete pwx-disk-1 --quiet
gcloud compute disks delete pwx-disk-2 --quiet
gcloud compute disks delete pwx-disk-3 --quiet
