# Poder
`kubectl run` wrapper

## Run
```
docker run -it --rm -v ${PWD}:/cwd -w /cwd poder -d -s="k8s.cluster.local" -t="********" -p="./example.json"
```
```
docker run -it --rm -v ${PWD}:/cwd -w /cwd -v $env:USERPROFILE\.kube:/kube -e KUBECONFIG="/kube/config" poder -d -k -p="./example.json"
```
