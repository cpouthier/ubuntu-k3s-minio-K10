#!/bin/bash
clear 
echo ""
echo ""
echo -e "\033[0;101m Do you want to setup a secondary cluster and enable Multi-Cluster license management? (type yes or no and hit Enter)\e[0m"
read choice < /dev/tty
echo ""

if [ "$choice" = "yes" ]; 
    then
        echo "Displaying again kubeconfig contexts:"
        echo "" 
        kubectl config get-contexts
        echo ""
        echo -e "\033[0;101m Which context is used for your secondary cluster?\e[0m"
        echo ""
        echo -e "\033[0;102m Enter the secondary context name:\e[0m"
        read secondary_context_name < /dev/tty
        echo ""
        echo -e "\033[0;101m What is the name of your secondary cluster?\e[0m"
        echo ""
        echo -e "\033[0;102m Enter the secondary cluster name:\e[0m"
        read secondary_cluster_name < /dev/tty
        echo ""
        echo -e "\033[0;101m What is the external ingress for the secondary cluster?\e[0m"
        echo ""
        echo -e "\033[0;102m Enter the ingress path URL:\e[0m"
        read secondary_ingress_path_url < /dev/tty
        echo ""
        echo ""
        k10multicluster setup-primary --context=$primary_context_name default --name=$primary_cluster_name --ingress=$primary_ingress_path_url
        k10multicluster bootstrap \
            --primary-context=$primary_context_name \
            --primary-name=$primary_cluster_name \
            --primary-cluster-ingress=$primary_ingress_path_url \
            --secondary-context=$secondary_context_name \
            --secondary-name=$secondary_cluster_name \
         --secondary-cluster-ingress=$secondary_ingress_path_url
        echo ""
        echo ""
        echo -e "\033[0;102m Kasten instance on cluster $primary_cluster_name available at $primary_ingress_path is now configured as the Kasten primary cluster.\e[0m"
        echo -e "\033[0;102m Cluster $secondary_cluster_name has been added as secondary cluster.\e[0m"
else
    if [ "$choice" = "no" ]; 
        then
            k10multicluster setup-primary --context=$primary_context_name default --name=$primary_cluster_name --ingress=$primary_ingress_path_url
            echo ""
            echo -e "\033[0;102m Kasten instance on cluster $primary_cluster_name available at $primary_ingress_path_url is now configured as the Kasten primary cluster.\e[0m"
            echo ""
            echo ""
        else
            echo ""
            echo "Sorry I didn't understand your answer..."
            echo ""
            curl -s https://raw.githubusercontent.com/cpouthier/kasten-scripts/main/multicluster_restart.sh | bash
    fi
fi