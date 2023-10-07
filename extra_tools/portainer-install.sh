helm repo add portainer https://portainer.github.io/k8s/
helm repo update
#by default expose through https on port 30779
helm upgrade --install --create-namespace -n portainer portainer portainer/portainer --set tls.force=true
