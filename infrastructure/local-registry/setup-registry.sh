#!/bin/bash

set -e

# Create a docker network for communication between KIND and registry
docker network create kind-net
echo "Kind-net network created!"

echo "Setting up local container registry..."
# Create local registry container if it doesn't exist
if ! docker ps -a | grep -q "registry"; then
    docker run -d -p 5000:5000 --restart=always --name registry registry:2
    echo "Local registry created at localhost:5000"
else
    echo "Local registry already exists"
fi

# Connect each KIND cluster to the network
docker network connect kind-net dev-cluster-control-plane
docker network connect kind-net qa-cluster-control-plane
docker network connect kind-net prod-cluster-control-plane
echo "Kind-net network binded to Kind Clusters!"

# Connect KIND clusters to local registry
for CLUSTER in dev-cluster qa-cluster prod-cluster; do
    echo "Configuring $CLUSTER to use local registry..."
    kubectl --context kind-$CLUSTER apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: local-registry-hosting
  namespace: kube-public
data:
  localRegistryHosting.v1: |
    host: "localhost:5000"
    help: "https://kind.sigs.k8s.io/docs/user/local-registry/"
EOF

    # For development purposes, allow insecure registries in containerd config
    for node in $(kind get nodes --name $CLUSTER); do
        docker exec $node sh -c "echo '{ \"insecure-registries\" : [\"localhost:5000\"] }' > /etc/docker/daemon.json"
    done
done

echo "Local registry setup complete!"