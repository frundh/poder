#!/bin/bash

set -eo pipefail

SERVER="k8s.cluster.local"
TOKEN="*******"
NAME="tmp-pod"
IMAGE="ubuntu"
NAMESPACE="default"
JSONPATH="./pod.json"
KUBEMOUNT=false
DEBUG=false

function usage()
{
cat << EOF
usage: poder [options][-h (--help)]

options:
    -s --server="$SERVER"
    -t --token="$TOKEN"
    -c --name="$NAME"
    -i --image="$IMAGE"
    -n --namespace="$NAMESPACE"
    -p --json-path="$JSONPATH"
    -k --kube-mount=$KUBEMOUNT
    -d --debug=$DEBUG

EOF
}

while [ "$1" != "" ]; do
    PARAM=`echo $1 | awk -F= '{print $1}'`
    VALUE=`echo $1 | awk -F= '{print $2}'`
    case $PARAM in
        -h | --help)
            usage
            exit
            ;;
        -s | --server)
            SERVER=$VALUE
            ;;
        -t | --token)
            TOKEN=$VALUE
            ;;
        -c | --name)
            NAME=$VALUE
            ;;
        -i | --image)
            IMAGE=$VALUE
            ;;
        -n | --namespace)
            NAMESPACE=$VALUE
            ;;
        -p | --json-path)
            JSONPATH=$VALUE
            ;;
        -k | --kube-mount)
            KUBEMOUNT=$VALUE
            ;;
        -d | --debug)
            DEBUG=true
            ;;
        *)
            echo "ERROR: unknown parameter \"$PARAM\""
            usage
            exit 1
            ;;
    esac
    shift
done

set -u
if [ "$DEBUG" = true ]; then set -x; fi

run_args=(
    --insecure-skip-tls-verify=true
    --generator=run-pod/v1 
    $NAME
    -n $NAMESPACE
    -i
    --rm
    --tty
    --restart=Never
    --pod-running-timeout=1m0s
    --requests=cpu=100m,memory=256Mi
    --limits=cpu=200m,memory=512Mi
    --image $IMAGE 
)

cmd=$(jq -r '.command' < $JSONPATH)

env=("$@")
for row in $(cat $JSONPATH | jq -r '.env[] | @base64'); do
    env+=("$(echo ${row} | base64 --decode)");
done

cmd_args=("$@")
for row in $(cat $JSONPATH | jq -r '.args[] | @base64'); do
    cmd_args+=("$(echo ${row} | base64 --decode)");
done

env_args=("${env[@]/#/--env=}")
run_args=("${run_args[@]}" "${env_args[@]}")

if [ -n "$cmd" ]; then run_args+=('--command'); fi
if [ -n "$cmd" ] || [ ! ${#cmd_args[@]} -eq 0 ]; then run_args+=('--'); fi

if [ "$KUBEMOUNT" = false ]; then
    kubectl config set-cluster mycluster --server=$SERVER
    kubectl config set-context mycluster --cluster=mycluster
    kubectl config set-credentials user --token=$TOKEN
    kubectl config set-context mycluster --user=user
    kubectl config use-context mycluster
fi

kubectl run ${run_args[@]} ${cmd} "${cmd_args[@]}"
