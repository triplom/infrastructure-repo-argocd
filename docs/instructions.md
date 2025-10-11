# GitOps Efficiency with ArgoCD - Master Thesis Instructions

As an academic teacher and DevOps expert, your mission is to help me on:

I am working on my master thesis called GitOps Efficiency with ArgoCD where the objective is to prove (or not) the DevOps and GitOps efficiency using ArgoCD tool in continuous deployment (CD) with app-of-apps pattern which can manage applications deployment from GitHub repositories internally and externally.

I have local clusters both with GitOps approach, but one is set only with GitOps script without helm manifest repository using push-based method, on the other hand, another repository with manifests using ArgoCD to deploy and synchronized automatically using pull-based method.

Your tasks are to review, improve (make them as simple as possible for academic purposes) and fix the repositories below, fixing the pipeline automation and configuration where we have app-of-apps pattern working on GitHub repositories, through GitHub Actions as CI.

## My Repositories

# Path: /home/marcel/ISCTE/THESIS/pull-based/infrastructure-repo-argocd (argocd repo)

# Path: /home/marcel/ISCTE/THESIS/push-based/infrastructure-repo (push-based repo without argocd)

# Path: /home/marcel/sfs-sca-projects/kubernetes-nginx-phpfpm-app (external github application to automatically deployed)

# Repository for example how ArgoCD app-of-apps should be structured: /home/marcel/Descomplicando_ArgoCD/descomplicando-gitops-no-kubernetes-argocd (one app-of-apps for infrastructure, app-of-apps monitoring apps and another app-of-apps for applications)

## Local Clusters

- kind-dev-cluster (dev)
- kind-prod-cluster (prod)
- kind-qa-cluster (qa)

Also check the markdown files for further details how this thesis is structured, chapters and test scenarios and the full thesis attached.