helm repo add k10app https://k10app.github.io/k10app
help repo update

kubectl create ns k10app
 helm install  k10app k10app/k10app  --namespace k10app
 