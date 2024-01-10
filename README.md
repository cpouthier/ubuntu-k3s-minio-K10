# ubuntu-k3s-minio-K10
Simple script to configure a signle node Kubernetes cluster based on K3s and extra tools such as Minio and Kasten K10.

This script is largely inspired from https://blog.kodu.uk/2023/05/17/kasten-k10-guide-for-beginners-part-4/

## What is this about?

This script will:

Setup apt and tune the environment
   
   Setup username, password and drive path as environement variables for further reference
   
   Install Helm
   
   Install K3s without Traeffik
   
   Tune bash for kubectl command for autocompletion
   
   Install Minio and create one standard bucket and one immutable bucket
   
   Install zfs and configure a pool then configure the storage class in K3s
   
   Install NGINX
   
   Install Kasten K10 and expose dashboard
   
   Create one location profile for each Minio bucket
   
   Enable daily Kasten reports
   
   Install Pacman app and expose it on port 80
   
   Set up a daily backup and export policy for Pacman
   
## Pre-requisites

This scripts has been tested on a Ubuntu 22.04 (AMD64), it may also apply for other operating system releases.

In order to work properly, ensure you'll get **at least 8GB of memory available** for the whole environement. 

Also ensure curl, wget are available and installed onto the server.

ZFS needs to get some **unformatted disk space** to create the proper storage pool for Kasten.

You may need to use fdisk (fdisk /dev/xxx) command in order to create a new unformatted partition which will be assigned to the ZFS pool when executing the script. Keep in m ind that Kasten needs roughly 80GB of storage to deploy, so plan accordingly and enseure you'll get also enough storage for your applications.

Run the script as su (sudo su):

```console
curl -s https://raw.githubusercontent.com/cpouthier/ubuntu-k3s-minio-K10/main/installscript.sh | bash
```
