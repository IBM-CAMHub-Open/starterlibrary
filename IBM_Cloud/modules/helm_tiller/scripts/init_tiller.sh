#!/bin/bash

mkdir -p $CLUSTER_NAME

# persist the cluster config .yaml file
echo "$CLUSTER_CONFIG" > $CLUSTER_NAME/config.yaml

# persist the cluster certificate_authority .pem file

export CLUSTER_CERTIFICATE_AUTHORITY_FILENAME=`echo "$CLUSTER_CONFIG" | grep certificate-authority | cut -d ":" -f 2 | tr -d '[:space:]'` \
&& echo "$CLUSTER_CERTIFICATE_AUTHORITY" > $CLUSTER_NAME/$CLUSTER_CERTIFICATE_AUTHORITY_FILENAME

# install helm locally  
wget --quiet https://storage.googleapis.com/kubernetes-helm/helm-v$HELM_VERSION-linux-amd64.tar.gz -P $CLUSTER_NAME \
&& tar -xzvf $CLUSTER_NAME/helm-v$HELM_VERSION-linux-amd64.tar.gz -C $CLUSTER_NAME

# helm init
export KUBECONFIG=$CLUSTER_NAME/config.yaml \
    && $CLUSTER_NAME/linux-amd64/helm init --upgrade --force-upgrade --tiller-connection-timeout 300 --service-account=default

