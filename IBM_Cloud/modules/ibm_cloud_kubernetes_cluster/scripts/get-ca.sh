#!/bin/bash
set -e
eval "$(jq -r '@sh "IKS_CA_COMMAND=\(.command) IKS_CLUSTER_NAME=\(.cluster)"')"

eval "$IKS_CA_COMMAND"
IKS_CERTIFICATE_AUTHORITY_LOCATION=`cat certificate_authority_location`
jq -n --arg certificate_authority_location "$IKS_CERTIFICATE_AUTHORITY_LOCATION" --arg cluster_name "$IKS_CLUSTER_NAME" '{($cluster_name):$certificate_authority_location}'