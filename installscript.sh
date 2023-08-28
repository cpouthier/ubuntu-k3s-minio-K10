#! /bin/bash
##new version of the script
# the following command will set the ubuntu service restart under apt to automatic
#Installation done on Ubuntu 22.04.3 LTS
sed -i 's/#$nrconf{restart} = '"'"'i'"'"';/$nrconf{restart} = '"'"'a'"'"';/g' /etc/needrestart/needrestart.conf
echo -e "$G Installing pre-req's...please standby..."
sleep 10
apt update
# apt -qq install apache2-utils ruby-rubygems -y --> do we need apache 2 to be installed for K10??



#Setting up interactively some environment variables to run this script
echo "Kasten will be installed with basic authentication, hence the need to provide a username and a password."
echo "You will use also those credentials to connect to Minio."
echo "Enter the username: "
read username < /dev/tty
echo "Enter the password: "
read password < /dev/tty
htpasswd_entry=$(htpasswd -nbm "$username" "$password" | cut -d ":" -f 2)
htpasswd="$username:$htpasswd_entry"
echo "Successfully generated htpasswd entry: $htpasswd"
echo "Please wait..."
sleep 5
fdisk -l
echo ""
echo " Enter drive path of extra volume (ie /dev/sdb) to set up Kasten K10 zfs pool: "
read DRIVE < /dev/tty

#Install curl and wget if not present
pro config set apt_news=false
apt -qq update && apt -qq upgrade -y && apt -qq dist-upgrade -y && apt -qq autoremove -y
sudo apt install -y curl wget

#Install Helm
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod +x ./get_helm.sh
./get_helm.sh

#Installing k3s single node cluster with local storage disabled 
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable local-storage" sh -s -
mkdir /root/.kube
cp /etc/rancher/k3s/k3s.yaml /root/.kube/config
chmod 600 ~/.kube/config && export KUBECONFIG=~/.kube/config

#Checking k3s installation
sleep 60
k3s check-config
kubectl cluster-info
kubectl get nodes -o wide

#Installing Minio
wget https://dl.min.io/server/minio/release/linux-amd64/minio -P /root
chmod +x /root/minio
mv /root/minio /usr/local/bin
mkdir /minio
MINIO_ROOT_USER=$username MINIO_ROOT_PASSWORD=$password minio server /minio --console-address ":9001" &
echo "@reboot MINIO_ROOT_USER=$username MINIO_ROOT_PASSWORD=$password minio server /minio --console-address ":9001"" > /root/minio_cron
crontab /root/minio_cron
get_ip=$(hostname -I | awk '{print $1}')
echo "Minio console is available on  http://"$get_ip":9001, with the same username/password you set, and the API available on port 9000."
echo "Please wait 10 sec..."
sleep 10



#Install zfs and configure kasten-pool storage pool on associated drive
apt install zfsutils-linux open-iscsi jq -y
zpool create kasten-pool $DRIVE
#
#Configure zfs storage class
kubectl apply -f https://openebs.github.io/charts/zfs-operator.yaml
curl -s https://raw.githubusercontent.com/cpouthier/ubuntu-k3s-minio-K10/main/k10-zfs-sc.yaml > zfs-sc.yaml
curl -s https://raw.githubusercontent.com/cpouthier/ubuntu-k3s-minio-K10/main/k10-zfs-snapshotclass.yaml > zfs-snapclass.yaml
kubectl apply -f zfs-sc.yaml
kubectl apply -f zfs-snapclass.yaml
kubectl patch storageclass kasten-zfs -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
#
#Adding kubectl autocompletion to bash
echo 'source <(kubectl completion bash)' >>~/.bashrc
source <(kubectl completion bash)
#
#Install Longhorn Storage & VolumeSnapshotClass
echo -e "$G Installing Longhorn Storage & VolumeSnapshotClass"
helm repo add longhorn https://charts.longhorn.io
helm repo update
helm install longhorn longhorn/longhorn --namespace longhorn-system --create-namespace -f https://raw.githubusercontent.com/cpouthier/ubuntu-k3s-minio-K10/main/longhorn-values.yaml
curl -s https://raw.githubusercontent.com/cpouthier/ubuntu-k3s-minio-K10/main/longhorn-snapshotclass.yaml > longsnapclass.yaml
kubectl apply -f longsnapclass.yaml
#
#Install Kasten K10
#Run Kasten k10 primer
curl https://docs.kasten.io/tools/k10_primer.sh | bash
#
#Adding and updating Helm repository
helm repo add kasten https://charts.kasten.io
helm repo update
#
#What is this used for?
#sysctl fs.inotify.max_user_watches=524288
#sysctl fs.inotify.max_user_instances=512
#echo "fs.inotify.max_user_watches = 524288" >> /etc/sysctl.conf
#echo "fs.inotify.max_user_instances = 512" >> /etc/sysctl.conf
#
#Create kasten-io namespace
kubectl create ns kasten-io
#Install Kasten in the kasten-io namespace with basic authentication
helm install k10 kasten/k10 --namespace kasten-io --set "auth.basicAuth.enabled=true" --set auth.basicAuth.htpasswd=$htpasswd
echo ""
echo "Please wait for 60sec whilst we wait for the pods to spin up..."
echo "After this period the external URL for K10 access will display (DO NOT exit this script)"
sleep 60
echo ""
#Finding the Kasten K10 gateway namespace name
pod=$(kubectl get po -n kasten-io |grep gateway | awk '{print $1}' )
#Expose the gateway pod through the load balancer on port 8000
kubectl expose po $pod -n kasten-io --type=LoadBalancer --port=8000 --name=k10-dashboard
#Setting up Kasten k10 ingress
curl https://raw.githubusercontent.com/cpouthier/ubuntu-k3s-minio-K10/main/k10-ingress.yaml > kasten-ingress.yaml
kubectl apply -f kasten-ingress.yaml -n kasten-io
echo "Kasten k10 is installed and can be accessed on http://"$get_ip":8000/k10/#/ using credentials set up earlier in this script" 


#Optional: deploying a sample pacman application
kubectl create ns pacman
helm repo add pacman https://shuguet.github.io/pacman/
helm install pacman pacman/pacman -n pacman --create-namespace --set service.type=LoadBalancer
echo "Please wait 5sec for the pacman app to spin up..."
sleep 5
curl https://raw.githubusercontent.com/cpouthier/ubuntu-k3s-minio-K10/main/pacman-ingress.yaml > pacman-ingress.yaml
kubectl apply -f pacman-ingress.yaml -n pacman
#Finding the Kasten K10 gateway namespace name
#pod=$(kubectl get po -n pacman |grep gateway | awk '{print $1}' )


kubectl get po pacman-844b99555f-rt5m2 -n pacman --type=LoadBalancer --port 8001 --name=pacmanwebui

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
