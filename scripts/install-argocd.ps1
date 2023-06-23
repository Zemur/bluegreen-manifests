class ArgoCDInstall {

    [string]$GitRootDir
    [System.Collections.ArrayList]$ManifestsToApply
    [string]$ArgoStacksPath
    [string]$ArgoAppSetsPath

    ArgoCDInstall () {
        ## Default Constructor
        Write-Host "Using default constructor"
        $this.GitRootDir = git rev-parse --show-toplevel
        $this.ManifestsToApply = [System.Collections.ArrayList]::new()
        $this.ArgoStacksPath = "$($this.GitRootDir)/argocd/argocd-stacks"
        $this.ArgoAppSetsPath = "$($this.GitRootDir)/argocd/application-manifests"
    }

    ArgoCDInstall ([string] $GitRootDir, $ArgoStacksPath, $ArgoAppSetsPath) {
        Write-Host "Using overloaded constructor"
        ## Overloaded constructor to allow specification of stacks and appsets
        $this.GitRootDir = git rev-parse --show-toplevel
        $this.ManifestsToApply = [System.Collections.ArrayList]::new()
        $this.ArgoStacksPath = "$($this.GitRootDir)/${ArgoStacksPath}"
        $this.ArgoAppSetsPath = "$($this.GitRootDir)/${ArgoAppSetsPath}"
    }

    [void] CreateNamespaces([System.Collections.ArrayList]$Namespaces) {
        ## Create Kubernetes Namespace
        foreach ($ns in $Namespaces) {
            Write-Host "Attempting to create ${ns}."
            if (!(kubectl get namespace $ns) 2> $null ) {
                $this.WriteBorderMessage("Creating Namespace")
                Write-Host "Creating ${ns}."
                kubectl create namespace $ns
            }
            else {
                Write-Host "${ns} already exists."
            }
        }
    }

    [void] ApplyKustomization() {
        ## Apply kustomization
        foreach ($Kustomization in $this.ManifestsToApply) {
            $this.WriteBorderMessage("Applying ${Kustomization}...")
            $cmdOutput = kubectl apply -k $Kustomization | Out-string
            Write-Host $cmdOutput

        }
    }

    [void] WriteBorderMessage([string]$Message, [string]$BorderChar){
        ## Write bordered messages.
        $StatusMessage = "${BorderChar} ${Message} ${BorderChar}"
        $Border = "${BorderChar}" * ($StatusMessage.Length)
        $BorderWall = "${BorderChar}" + " "* ($Border.Length - 2) + "${BorderChar}"
        Write-Host "`n${Border}`n${BorderWall}`n${StatusMessage}`n${BorderWall}`n${Border}"
    }

    [void] WriteBorderMessage([string]$Message) {
        ## Overloaded Write-BorderMessage for default $BorderChar
        $BorderChar="*"
        $this.WriteBorderMessage($Message, $BorderChar)
    }
}

# Instantiate ArgoCDInstall with default constructor
$ArgoInstall = [ArgoCDInstall]::new()

# Create namespaces if they do not exist.
$ArgoInstall.CreateNamespaces([System.Collections.ArrayList]@('blue', 'green' | % { "argocd-$_" }))

# Add Manifests for ArgoCD blue and green servers.
Write-Output "Adding ArgoCD Blue Green Stacks"
foreach ($color in @('blue', 'green')) {
    $ArgoInstall.ManifestsToApply.Add("$($ArgoInstall.ArgoStacksPath)/overlays/${color}") > $null
}

# Add Manifests for Istio Configuration.
Write-Output "Adding Istio Configuration"
$ArgoInstall.ManifestsToApply.Add(("$($ArgoInstall.ArgoStacksPath)/base/argocd-bluegreen-ingress")) > $null

# Add Manifests for the test-webpage application set.
Write-Output "Adding test-webpage manifests"
foreach ($color in @('blue', 'green')) {
    $ArgoInstall.ManifestsToApply.Add("$($ArgoInstall.ArgoAppSetsPath)/test-webpage/overlays/${color}") > $null
}

# Apply Manifests
Write-Output "Applying Manifests"
$argoInstall.ApplyKustomization()


