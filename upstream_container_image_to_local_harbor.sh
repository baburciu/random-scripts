#! /bin/bash

# Fetch container image from upstream and push to local registry
# -------------------------
# How to run: 
# export DOCKER_USERNAME=<destination_registry_username> DOCKER_PASSWORD=<destination_registry_pass>
# ./upstream_container_image_to_local_harbor.sh -s fluxcd/helm-controller:v0.21.0 -d <Harbor>/bogdan.burciu
#   or
# ./upstream_container_image_to_local_harbor.sh -s quay.io/metal3-io/ip-address-manager:v1.1.2 -d <destination_registry_ip>:<destination_registry_port>


# configure script to exit as soon as any line in the bash script fails and show that line
set -e

# using flags for passing input to script
while getopts s:d: flag
do
    case "${flag}" in
        s) source_image=${OPTARG};;
        d) destination_repo=${OPTARG};;
    esac
done

echo -e "\t\t >> docker image pull $source_image"
docker image pull $source_image
source_image_repo=`echo $source_image | awk -F":" '{print $1}'`
source_image_repo_after1stslash=${source_image_repo#*/}
source_image_repo_before1stslash=${source_image_repo%"$source_image_repo_after1stslash"}

# if the image name starts with the fqdn of a container registry, containing ".", then skip it from the name
if [[ $source_image_repo_before1stslash == *"."* ]]; then
    source_image_repo=$source_image_repo_after1stslash
fi

source_image_tag=`echo $source_image | awk -F":" '{print $2}'`
image_id=`docker image ls | grep $source_image_repo | grep $source_image_tag | grep -v $destination_repo | awk {'print $3'}`
echo $image_id
echo $destination_repo
echo -e "\t\t >> docker tag $image_id $destination_repo/$source_image_repo:$source_image_tag"
docker tag $image_id $destination_repo/$source_image_repo:$source_image_tag
destination_repo_fqdn=`echo $destination_repo | awk -F"/" '{print $1}'`
echo -e "\t\t >> docker login $destination_repo_fqdn"
docker login $destination_repo_fqdn -u="${DOCKER_USERNAME}" -p="${DOCKER_PASSWORD}"
echo -e "\t\t >> docker push $destination_repo/$source_image_repo:$source_image_tag"
docker push $destination_repo/$source_image_repo:$source_image_tag
