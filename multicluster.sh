#!/bin/bash
clear
echo ""
echo ""
echo -e "\033[0;101m Before running this script, visit https://github.com/kastenhq/external-tools/releases and find the appropriate k10multicluster package depending on your Kasten version, OS and architecture. \e[0m"
echo -e "\033[0;101m Then, copy the k10multicluster package link in your clipboard as it will be requested by the script.\e[0m"
echo -e "\033[0;101m \e[0m"
echo -e "\033[0;101m For additional information, please check https://docs.kasten.io/latest/multicluster/bootstrap_reference.html#bootstrapping-commands-reference\e[0m"
echo -e "\033[0;104m \e[0m"
echo -e "\033[0;102m Paste the k10multicluster package URL and press Enter: \e[0m"
read package_URL < /dev/tty
echo "Downloading package..."
wget $package_URL
echo "Decompressing the package..."
tar -xvf k10multicluster*.tar.gz 
mv k10multicluster /usr/local/bin/k10multicluster
rm k10multicluster_*.tar.gz
clear
echo ""
echo "Get contexts from kubeconfig..."
echo ""
kubectl config get-contexts
echo ""
echo ""
echo -e "\033[0;102m Enter your primary cluster context name and press Enter: \e[0m"
echo ""
read primary_context_name < /dev/tty
echo ""
echo -e "\033[0;102m Enter your primary cluster name and press Enter: \e[0m"
echo ""
read primary_cluster_name < /dev/tty
echo ""
echo -e "\033[0;102m Enter your primary cluster ingress path URL and press Enter: \e[0m"
echo ""
read primary_ingress_path_url < /dev/tty
echo ""
curl -s https://raw.githubusercontent.com/cpouthier/kasten-scripts/main/multicluster_restart.sh | bash