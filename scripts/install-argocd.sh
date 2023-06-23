#!/usr/bin/env bash

writeBorderMessage() {
    message="$1"
    msgLen=$((${#message} + 4))

    printf '%*s\n' $msgLen "" | tr ' ' '*'
    printf "* %*s *\n" $(($msgLen - 4)) ""
    printf "* %s *\n" "${message}"
    printf "* %*s *\n" $(($msgLen - 4)) ""
    printf '%*s\n' $msgLen "" | tr ' ' '*'
}

gitRootDir=$(git rev-parse --show-toplevel)
argoStacksPath="${gitRootDir}/argocd/argocd-stacks"
argoAppSetsPath="${gitRootDir}/argocd/application-manifests"
namespaces=("argocd-"{blue,green})
manifests=("${argoStacksPath}/overlays/"{blue,green} "${argoStacksPath}/base/argocd-bluegreen-ingress" "${argoAppSetsPath}/test-webpage/overlays/"{blue,green})

# Create Namespaces
for ns in $namespaces; do
    kubectl get namespace $ns
    if [ $? == 0 ]; then
        echo "${ns} already exists"
    else
        echo "Creating ${ns}"
        kubectl create namespace $ns
    fi
done

# Apply Manifests
for kustomization in ${manifests[*]}; do
    writeBorderMessage "Applying ${kustomization}..."
    kubectl apply -k $kustomization
done