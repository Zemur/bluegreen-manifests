# ArgoCD Blue Green Manifests

## Assumptions
This example is written with the assumption that you have a Vault server set up, the [argocd-vault-plugin](https://www.argocd-vault-plugin.readthedocs.io/en/stable/) CLI
installed locally, and [Istio](https://www.istio.io/) installed and configured on the server.

## ArgoCD Blue-Green Stack Setup
The ArgoCD configuration is under `argocd/argocd-stacks/`. To set up the server you need to apply the appropriate overlay, e.g.,
`kubectl apply -k argocd/argocd-stacks/overlays/blue` or `kubectl apply -k argocd/argocd-stacks/overlays/green`.

### Components
Both of these stacks pull components from
`argocd/argocd-stacks/components/argocd-components`. Common configuration for the ArgoCD servers is stored here.

### Why use blue and green bases?
Due to the way that ArgoCDs install manifests work with Kustomize, it is separated into two bases `argocd/argocd-stacks/base/blue` and
`argocd/argocd-stacks/base/green`. If the manifests were applied in a single base, it would throw an error due to the order the manifests are run
during build time. The `argocd/argocd-stacks/overlays/` can be extended to deploy to multiple clusters such as
`argocd/argocd-stacks/overlays/development/$color` and `argocd/argocd-stacks/overlays/production/$color` and modifying the relative directories within the
`kustomization.yaml` files.

## ArgoCD Application and ApplicationSet Manifests
The application manifests are under `argocd/application-manifests`. These can be either a single application resource or an application set.

## Example Application Configuration
An example application, `test-webpage`, is included in repository and used by the ApplicationSet defined under `application-manifest/test-webpage`.
It includes a blue-green setup of its own, not to be confused with the blue-green stacks for ArgoCD. The setup for these could be thought of as follows:
```
└───argocd-servers
    ├───blue-stack
    │   ├───test-webpage-blue
    │   └───test-webpage-green
    └───green-stack
        ├───test-webpage-blue
        └───test-webpage-green
```

The weight for each route is set to 50 in `apps/test-webpage/base/networking/resources/virtualservice.yaml`. This can be adjusted as needed for testing
traffic routing.