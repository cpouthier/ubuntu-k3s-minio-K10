#! /bin/bash
# This script should be used only to resume Kasten K10 install
# Run Kasten k10 primer
curl https://docs.kasten.io/tools/k10_primer.sh | bash
echo "Please exit this script within the next 15sec to fix any error before installing Kasten K10."
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
echo "Kasten k10 is installed and can be accessed on http://"$get_ip":8000/k10/#/ using credentials set up earlier in this script"