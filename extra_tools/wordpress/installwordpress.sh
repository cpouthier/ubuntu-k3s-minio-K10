kubectl create namespace wordpress
helm install wordpress bitnami/wordpress --namespace wordpress 
echo ""
kubectl apply -f wordpress-nodeport.yaml
#find the wordpress ONLY pod (without mariadb) and set the pod variable
pod=$(kubectl get po -n mywebsite |grep wordpress | grep -v mariadb | awk '{print $1}')
echo "On wich port do want to expose you blog?"
read EXTPORT < /dev/tty
kubectl expose po $pod -n mywebsite --type=NodePort --port=$EXTPORT --name=webgui
get_ip=$(hostname -I | awk '{print $1}')
clear
echo ""
echo -e "\033[0;32m Wordpress is installed and can be accessed on http://"$get_ip":"$EXTPORT"/admin using credentials hereunder:\e[0m"
echo ""
echo Username: user
echo Password: $(kubectl get secret --namespace mywebsite wordpress -o jsonpath="{.data.wordpress-password}" | base64 -d)
echo ""