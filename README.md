# ubuntu-k3s-minio-K10
Simple script to configure a signle node Kubernetes cluster based on K3s and extra tools such as Minio and Kasten K10.

**What is this about?**

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

**Pre-requisites**

This scripts has been tested on a Ubuntu 22.04, it may also apply for other operating system releases.

Also ensure curl and wget are already installed.

ZFS needs to get some unformatted disk space to create the proper storage pool for Kasten.

Run the script as su (sudo su):

```console
curl -s https://raw.githubusercontent.com/cpouthier/ubuntu-k3s-minio-K10/main/installscript.sh | bash
```
