$GitRootDir = git rev-parse --show-toplevel
$ArgoStacksBasePath = "${GitRootDir}/argocd/argocd-stacks"
$ManifestsToApply = "blue", "green" | % { "$ArgoStacksBasePath/overlays/$_" }
$ManifestsToApply += "$ArgoStacksBasePath/base/argocd-bluegreen-ingress"
$ManifestsToApply += "blue", "green" | % { "$ArgoStacksBasePath/application-manifests/test-webpage/$_"}

$Namespaces = 'blue', 'green' | % { "argocd-$_" }

foreach ($ns in $Namespaces) {
    kubectl create namespace $ns
}

foreach ($Kustomization in $ManifestsToApply) {
    Write-Output "Applying $Kustomization..."
    kubectl apply -k $Kustomization
}