
#Select the proper k10multicluster package before running this script visiting https://github.com/kastenhq/external-tools/releases

wget https://github.com/kastenhq/external-tools/releases/download/6.0.7/k10multicluster_6.0.7_linux_amd64.tar.gz
tar -xvf k10multicluster_6.0.7_linux_amd64.tar.gz 
mv k10multicluster /usr/local/bin/k10multicluster
rm k10multicluster_6.0.7_linux_amd64.tar.gz
kubectl config get-contexts
echo "Which context is used for your primary cluster?"
echo -e "\033[0;102m Enter the context name: \e[0m"
read context_name < /dev/tty
echo "What is the name of your primary cluster?"
echo -e "\033[0;102m Enter the primary cluster name: \e[0m"
read primary_cluster_name < /dev/tty
echo "What is the ingress path for your primary cluster?"
echo -e "\033[0;102m Enter the ingress path URL: \e[0m"
read ingress_path < /dev/tty
k10multicluster  setup-primary --context=$context_name default --name=$primary_cluster_name --ingress=$ingress_path

