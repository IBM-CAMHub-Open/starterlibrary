#!/bin/bash
mkdir -p $CLUSTER_NAME

# persist the cluster config .yaml file
echo "$CLUSTER_CONFIG" > $CLUSTER_NAME/config.yaml

# persist the cluster certificate_authority .pem file

export CLUSTER_CERTIFICATE_AUTHORITY_FILENAME=`echo "$CLUSTER_CONFIG" | grep certificate-authority | cut -d ":" -f 2 | tr -d '[:space:]'` \
&& echo "$CLUSTER_CERTIFICATE_AUTHORITY" > $CLUSTER_NAME/$CLUSTER_CERTIFICATE_AUTHORITY_FILENAME

#determine the platform architecture
ARCH=`uname -a | rev | cut -d ' ' -f2 | rev`
case $ARCH in
    x86_64)     PLATFORM='linux-amd64';;
    ppc64le)    PLATFORM='linux-ppc64le';;
esac

# install helm locally  
wget --quiet https://storage.googleapis.com/kubernetes-helm/helm-v$HELM_VERSION-$PLATFORM.tar.gz -P $CLUSTER_NAME \
&& tar -xzvf $CLUSTER_NAME/helm-v$HELM_VERSION-$PLATFORM.tar.gz -C $CLUSTER_NAME

# helm init
source $SCRIPTS_PATH/functions.sh
vercomp $HELM_VERSION '2.8.2'
case $? in
    0)  TILLER_CONNECTION_TIMEOUT=' --tiller-connection-timeout 300';;
    1)  TILLER_CONNECTION_TIMEOUT=' --tiller-connection-timeout 300';;
    2)  TILLER_CONNECTION_TIMEOUT=''
esac

vercomp $HELM_VERSION '2.7.2'
case $? in
    0)  FORCE_UPGRADE=' --force-upgrade';;
    1)  FORCE_UPGRADE=' --force-upgrade';;
    2)  FORCE_UPGRADE=''
esac

export KUBECONFIG=$CLUSTER_NAME/config.yaml \
    && $CLUSTER_NAME/$PLATFORM/helm init --upgrade $FORCE_UPGRADE $TILLER_CONNECTION_TIMEOUT --service-account=default
