#! /bin/bash
# This script will:
#   Setup apt and tune the environment
#   Setup username, password and drive path as environement variables for further reference
#   Install Helm
#   Install K3s
#   Tune bash for kubectl command for autocompletion
#   Install Minio
#   Install zfs and configure a pool then configure the storage class in K3s
#   Install longhorn and configure the volume snapshot class in K3s
#   Install Kasten K10 and expose dashboard
#   
# The following script will set the ubuntu service restart under apt to automatic
sed -i 's/#$nrconf{restart} = '"'"'i'"'"';/$nrconf{restart} = '"'"'a'"'"';/g' /etc/needrestart/needrestart.conf
apt update
sysctl fs.inotify.max_user_watches=524288
sysctl fs.inotify.max_user_instances=512
echo "fs.inotify.max_user_watches = 524288" >> /etc/sysctl.conf
echo "fs.inotify.max_user_instances = 512" >> /etc/sysctl.conf
# Installing apache2-utils to get htpasswd
apt install apache2-utils -y

# Setting up interactively some environment variables to run this script
echo "Kasten will be installed with basic authentication, hence the need to provide a username and a password."
echo "You will use also those credentials to connect to Minio."
echo -e "\033[0;102m Enter the username: \e[0m"
read username < /dev/tty
echo -e "\033[0;102m Enter the password: \e[0m"
read password < /dev/tty
htpasswd_entry=$(htpasswd -nbm "$username" "$password" | cut -d ":" -f 2)
htpasswd="$username:$htpasswd_entry"
echo "Successfully generated htpasswd entry: $htpasswd"
echo "Please wait..."
sleep 5
fdisk -l
echo ""
echo -e "\033[0;102m Enter drive path of extra volume (ie /dev/sdb) to set up Kasten K10 zfs pool: \e[0m"
read DRIVE < /dev/tty

# Install Helm
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod +x ./get_helm.sh
./get_helm.sh

#Install Kubectl for Linux AMD64
curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl

# Installing k3s single node cluster with local storage disabled 
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable local-storage" sh -s -
mkdir /root/.kube
cp /etc/rancher/k3s/k3s.yaml /root/.kube/config
chmod 600 ~/.kube/config && export KUBECONFIG=~/.kube/config
# Checking k3s installation
echo ""
echo "Please wait 60sec for k3s to spin up..."
sleep 60
k3s check-config
kubectl cluster-info
kubectl get nodes -o wide
echo ""
echo -e "\033[0;101m Please review k3s information (you have 15sec)... \e[0m"
sleep 15

# Adding kubectl autocompletion to bash
echo 'source <(kubectl completion bash)' >>~/.bashrc
source <(kubectl completion bash)

# Installing Minio for AMD64 outside K3s
echo ""
echo "The script is about to install minio for linux AMD64, please ensure you're running on this platform type, otherwise exit this script!"
echo ""
sleep 10
wget https://dl.min.io/server/minio/release/linux-amd64/minio -P /root
chmod +x /root/minio
mv /root/minio /usr/local/bin
mkdir /minio
MINIO_ROOT_USER=$username MINIO_ROOT_PASSWORD=$password minio server /minio --console-address ":9001" &
echo "@reboot MINIO_ROOT_USER=$username MINIO_ROOT_PASSWORD=$password minio server /minio --console-address ":9001"" > /root/minio_cron
crontab /root/minio_cron
get_ip=$(hostname -I | awk '{print $1}')
echo "Please wait 10 sec..."
sleep 10

# Install zfs and configure kasten-pool storage pool on associated drive
apt install zfsutils-linux open-iscsi jq -y
zpool create kasten-pool $DRIVE

# Configure zfs storage class
kubectl apply -f https://openebs.github.io/charts/zfs-operator.yaml
curl -s https://raw.githubusercontent.com/cpouthier/ubuntu-k3s-minio-K10/main/k10-zfs-sc.yaml > zfs-sc.yaml
curl -s https://raw.githubusercontent.com/cpouthier/ubuntu-k3s-minio-K10/main/k10-zfs-snapshotclass.yaml > zfs-snapclass.yaml
kubectl apply -f zfs-sc.yaml
kubectl apply -f zfs-snapclass.yaml
kubectl patch storageclass kasten-zfs -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

# Install Longhorn Storage & VolumeSnapshotClass
echo -e "$G Installing Longhorn Storage & VolumeSnapshotClass"
helm repo add longhorn https://charts.longhorn.io
helm repo update
helm install longhorn longhorn/longhorn --namespace longhorn-system --create-namespace -f https://raw.githubusercontent.com/cpouthier/ubuntu-k3s-minio-K10/main/longhorn-values.yaml
curl -s https://raw.githubusercontent.com/cpouthier/ubuntu-k3s-minio-K10/main/longhorn-snapshotclass.yaml > longsnapclass.yaml
kubectl apply -f longsnapclass.yaml

# Install Kasten K10
# Adding and updating Helm repository
helm repo add kasten https://charts.kasten.io
helm repo update
# Run Kasten k10 primer
curl https://docs.kasten.io/tools/k10_primer.sh | bash
echo "Please exit this script within the next 15sec to fix any error before installing Kasten K10. Then resume the Kasten K10 install with curl -s https://raw.githubusercontent.com/cpouthier/ubuntu-k3s-minio-K10/main/resume-k10-install.sh | bash"
sleep 15
# Create kasten-io namespace
kubectl create ns kasten-io
# Install Kasten in the kasten-io namespace with basic authentication
helm install k10 kasten/k10 --namespace kasten-io --set "auth.basicAuth.enabled=true" --set auth.basicAuth.htpasswd=$htpasswd
echo ""
echo "Please wait for 60sec whilst we wait for the pods to spin up..."
echo "After this period the external URL for K10 access will display (DO NOT exit this script)"
sleep 60
echo ""
# Finding the Kasten K10 gateway namespace name
pod=$(kubectl get po -n kasten-io |grep gateway | awk '{print $1}' )
# Expose the gateway pod through the load balancer on port 8000
kubectl expose po $pod -n kasten-io --type=LoadBalancer --port=8000 --name=k10-dashboard
# Setting up Kasten k10 ingress
curl https://raw.githubusercontent.com/cpouthier/ubuntu-k3s-minio-K10/main/k10-ingress.yaml > kasten-ingress.yaml
kubectl apply -f kasten-ingress.yaml -n kasten-io
echo ""
echo -e "\033[0;32m Kasten k10 is installed and can be accessed on http://"$get_ip":8000/k10/#/ using credentials set up earlier in this script ($username/$password)\e[0m"
echo ""
echo -e "\033[0;32m Minio console is available on  http://"$get_ip":9001, with the same username/password.\e[0m"
echo ""