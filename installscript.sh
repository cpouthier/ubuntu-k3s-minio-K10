#! /bin/bash
# the following command will set the ubuntu service restart under apt to automatic
sed -i 's/#$nrconf{restart} = '"'"'i'"'"';/$nrconf{restart} = '"'"'a'"'"';/g' /etc/needrestart/needrestart.conf
echo -e "$G Installing pre-req's...please standby..."
sleep 10
apt update
apt -qq install apache2-utils ruby-rubygems -y
gem install facter
echo -e "$R ____  ___                ___                            __    ____  _____ "
echo -e "$R|    |/ _|____    _______/  |_  ____   ____             |  | _/_   \   _  \ "
echo -e "$R|      < \__  \  /  ___/\   __\/ __ \ /    \    ______  |  |/ /|   /  /_\  \ "
echo -e "$R|    |  \ / __ \_\___ \  |  | \  ___/|   |  \  /_____/  |    < |   \  \_/   \ "
echo -e "$R|____|__ (____  /____  > |__|  \___  >___|  /           |__|_ \|___|\_____  / "
echo -e "$R        \/    \/     \/            \/     \/                 \/           \/ "
echo -e "$G Simple K10 node installer.....!"
sleep 1
echo ""
echo -e "$G This will install a single node k3s cluster with the OpenEBS ZFS csi driver, Longhorn csi driver and all k10 annotated volumesnapshotclasses"
sleep 1
echo ""
echo -e "$G Longhorn will operate in single REPLICA mode, so this cluster cannot have additional worker nodes added to it"
sleep 1
echo ""
echo -e "$G It will then install k10 via HELM and automatically expose the k10 dashboard on the cluster load balancer"
sleep 1
echo ""
echo -e "$G K10 will be install with Basic Authentication enabled and you need to enter the username and password you wish to use next: "
sleep 1
echo -e "$W"
echo "Enter the username: "
read username < /dev/tty
echo ""
echo "Enter the password: "
read password < /dev/tty
htpasswd_entry=$(htpasswd -nbm "$username" "$password" | cut -d ":" -f 2)
htpasswd="$username:$htpasswd_entry"
echo "Successfully generated htpasswd entry: $htpasswd"
echo ""
echo -e "$G Enter drive path of extra volume (ie /dev/sdb). If you do not know this exit this script by cmd-x and run "fdisk -l" to find the drive path: "
echo -e "$W "
read DRIVE < /dev/tty
sleep 5
echo ""
echo -e "$G Patching Ubuntu"
echo ""
sleep 5
echo -e "$W " 
pro config set apt_news=false
apt -qq update && apt -qq upgrade -y && apt -qq dist-upgrade -y && apt -qq autoremove -y
sleep 5
echo -e "$G Installing k3s single node cluster"
echo -e "$W "
sleep 5
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable local-storage" sh -s -
sleep 5
echo ""
echo -e "$G Installing ZFS and configuring pool"
echo -e "$W "
sleep 5
apt install zfsutils-linux open-iscsi jq -y
zpool create kasten-pool $DRIVE
sleep 5
echo ""
echo -e "$G Installing ZFS Operator, StorageClass & VolumeSnapshotClass"
echo -e "$W "
echo ""
echo -e "$R Waiting 60s for k3s to fully start!!"
echo -e "$W"
sleep 60
kubectl apply -f https://openebs.github.io/charts/zfs-operator.yaml
curl -s https://raw.githubusercontent.com/jdtate101/jdtate101/main/zfs-sc.yaml > zfs-sc.yaml
curl -s https://raw.githubusercontent.com/jdtate101/jdtate101/main/zfs-snapclass.yaml > zfs-snapclass.yaml
kubectl apply -f zfs-sc.yaml
kubectl apply -f zfs-snapclass.yaml
kubectl patch storageclass kasten-zfs -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
sleep 5
echo ""
echo -e "$G Installing Helm"
echo -e "$W "
sleep 5
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod +x ./get_helm.sh
./get_helm.sh
mkdir /root/.kube
cp /etc/rancher/k3s/k3s.yaml /root/.kube/config
helm repo add kasten https://charts.kasten.io
helm repo add longhorn https://charts.longhorn.io
sleep 5
echo ""
echo -e "$G Installing Longhorn Storage & VolumeSnapshotClass"
echo -e "$W "
helm repo update
helm install longhorn longhorn/longhorn --namespace longhorn-system --create-namespace -f https://raw.githubusercontent.com/jdtate101/jdtate101/main/longhorn-values.yaml
curl -s https://raw.githubusercontent.com/jdtate101/jdtate101/main/longsnapclass.yaml > longsnapclass.yaml
kubectl apply -f longsnapclass.yaml
sleep 5
echo -e "$W "
echo ""
echo -e "$G Installing Kasten K10"
echo -e "$W "
sleep 5
sysctl fs.inotify.max_user_watches=524288
sysctl fs.inotify.max_user_instances=512
echo "fs.inotify.max_user_watches = 524288" >> /etc/sysctl.conf
echo "fs.inotify.max_user_instances = 512" >> /etc/sysctl.conf
kubectl create ns kasten-io
helm install k10 kasten/k10 --namespace kasten-io --set "auth.basicAuth.enabled=true" --set auth.basicAuth.htpasswd=$htpasswd
echo ""
echo -e "$R Please wait for 60sec whilst we wait for the pods to spin up..."
echo -e "$R After this period the external URL for K10 access will display (DO NOT exit this script)"
sleep 60
echo -e "$W "
pod=$(kubectl get po -n kasten-io |grep gateway | awk '{print $1}' )
kubectl expose po $pod -n kasten-io --type=LoadBalancer --port=8000 --name=k10-dashboard
port=$(kubectl get svc -n kasten-io |grep k10-dashboard | cut -d':' -f2- | cut -f1 -d'/' )
curl https://raw.githubusercontent.com/jdtate101/jdtate101/main/kasten-ingress.yaml > kasten-ingress.yaml
kubectl apply -f kasten-ingress.yaml -n kasten-io
echo ""
get_public_ip=$(curl -s ifconfig.me)
get_local_ip=$(hostname -I | awk '{print $1}')
cloud_id=$(facter cloud |grep provider | cut -d'"' -f 2)
    if [[ ! -z $cloud_id ]]; then
        echo "Running on a cloud virtual machine"
        echo -e "$G K10 dashboard can be accessed on http://"$get_public_ip":"$port"/k10/#/"
    else
	echo "Running on a local machine / virtual machine"
	echo -e "$G K10 dashboard can be accessed on http://"$get_local_ip":"$port"/k10/#/"
    fi
echo -e "$W "
echo -e "$R It may take a while for all pods to become active. You can check with $G < kubectl get po -n kasten-io > $R wait for the gateway pod to go 1/1 before you go to the URL"
echo -e "$W "
echo -e "$R If you wish to access the longhorn UI you need to create an entry in your /etc/hosts file or local DNS for longhorn.local to point to IP Address: $ip ,then browse to http://longhorn.local"
echo -e "$W "
sleep 5
echo -e "$G"
echo "Installing minio S3 Storage.."
echo -e "$W"
wget https://dl.min.io/server/minio/release/linux-amd64/minio -P /root
chmod +x /root/minio
mv /root/minio /usr/local/bin
mkdir /minio
MINIO_ROOT_USER=$username MINIO_ROOT_PASSWORD=$password minio server /minio --console-address ":9001" &
echo "@reboot MINIO_ROOT_USER=$username MINIO_ROOT_PASSWORD=$password minio server /minio --console-address ":9001"" > /root/minio_cron
crontab /root/minio_cron
echo -e "$G"
echo "Minio console is available on port 9001 for the same IP address as the K10 interface (listed above), with the same username/password you set for the K10 instance, and the API available on port 9000"
sleep 2
echo ""
echo "Now deploying sample pacman application..."
echo -e "$W"
kubectl create ns pacman
helm repo add pacman https://shuguet.github.io/pacman/
helm install pacman pacman/pacman -n pacman
echo -e "$R"
echo "Waiting for pacman app to become available..please wait!"
sleep 5
curl https://raw.githubusercontent.com/jdtate101/jdtate101/main/pacman-ingress.yaml > pacman-ingress.yaml
kubectl apply -f pacman-ingress.yaml -n pacman
echo -e "$G"
echo ""
echo "Pacman application is exposed using an ingress rule. Please create a entry in your desktop /etc/hosts file or local DNS to point towards $ip for pacman.local"
echo "You can then access the pacman app on http://pacman.local"
echo ""
echo "The longhorn dashboard UI is available at http://longhorn.local . Please create an entry in the host file to access, much in the same fashion as you just did for the pacman app."
echo -e "$W"
echo ""
sleep 2
echo -e "$G"
echo "Hope you enjoy the Kasten environment....."
echo -e "$W"
echo ""
exit 
