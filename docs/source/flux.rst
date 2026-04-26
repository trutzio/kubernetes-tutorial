Flux
====

Installation
------------
Die Installation von Flux erfolgt über ein Bootstrap-Skript, das von der offiziellen Flux-Website bereitgestellt wird. Dieses Skript installiert Flux auf Ihrem Kubernetes-Cluster und richtet die Verbindung zu Ihrem GitHub-Repository ein. Hier ist ein Beispiel, wie man Flux installieren und konfigurieren kann:

.. code-block:: console

   $ curl -s https://fluxcd.io/install.sh | sudo bash
   $ export GITHUB_TOKEN=<gh-token> # siehe https://github.com/settings/personal-access-tokens
   # Administration -> Access: Read-only
   # Contents -> Access: Read and write
   # Metadata -> Access: Read-only
   $ flux bootstrap github --token-auth --owner=trutzio --repository=kubernetes-tutorial --branch=main --path=clusters/k3s/2026-04-28/
   $ kubectl get all -n flux-system
   $ flux get sources git
   $ kubectl get gitrepositories -n flux-system

https://fluxcd.io/flux/installation/bootstrap/github/ enthält die Github PAT Berechtigungen, die benötigt werden.

Das rolldice Flux-HelmRelease
-----------------------------

Zuerst erstellen wir ein GitRepository-Manifest, das Flux mitteilt, wo es die Helm-Charts für die Rolldice-Anwendung finden kann. Dieses Manifest verweist auf das GitHub-Repository, in dem die Helm-Charts gespeichert sind, und gibt an, wie oft Flux nach Änderungen suchen soll.

.. include:: ../../src/flux/github-gitrepository.yaml

Das folgende HelmRelease-Manifest definiert das Deployment der Rolldice-Anwendung über Flux.

.. include:: ../../src/flux/helm/rolldice-helmrelease.yaml
   
.. code-block:: console

   $ cd src/flux
   $ kubectl apply -f github-gitrepository.yaml
   $ flux get sources git -n default # oder
   $ kubectl get gitrepositories
   $ kubectl apply -f rolldice-helmrelease.yaml
   $ flux get helmreleases -n default # oder
   $ kubectl get helmreleases
   $ kubectl describe helmrelease/rolldice
   $ kubectl get all-l app=rolldice