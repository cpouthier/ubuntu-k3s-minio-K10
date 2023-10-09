# ubuntu-k3s-minio-K10
Simple script to configure a signle node Kubernetes cluster based on K3s and extra tools such as Minio and Kasten K10.

This script is largely inspired from https://blog.kodu.uk/2023/05/17/kasten-k10-guide-for-beginners-part-4/

## What is this about?

This script will:

   Setup apt and tune the environment

   Setup username, password and drive path as environement variables for further reference

   Install Helm

   Install K3s

   Tune bash for kubectl command for autocompletion

   Install Minio

   Install zfs and configure a pool then configure the storage class in K3s

   Install longhorn and configure the volume snapshot class in K3s

   Install Kasten K10 and expose dashboard 

## Pre-requisites

This scripts has been tested on a Ubuntu 22.04, it may also apply for other operating system releases.

Also ensure curl, wget and kubectl are already installed.

ZFS needs to get some unformatted disk space to create the proper storage pool for Kasten.

You may need to "play" with fdisk (fdisk /dev/xxx) command in order to create a new unformatted partition to be assigned to the ZFS pool.

Run the script as su (sudo su):

```console
curl -s https://raw.githubusercontent.com/cpouthier/ubuntu-k3s-minio-K10/main/installscript.sh | bash
```
# kasten-scripts
