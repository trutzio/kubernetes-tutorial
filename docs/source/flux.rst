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
   $ kubectl get all -l app.kubernetes.io/name=rolldice # pod ist nicht bereit, warum?
   $ kubectl logs -l app.kubernetes.io/name=rolldice # fehlerhafte Version, da kein liveliness und readiness
   $ # neue Version des Chats in Git pushen, damit Flux die Änderungen erkennt und das Deployment aktualisiert, die appVersion in Chart.yaml auf 1.0.1 erhöhen, damit Flux das Image mit liveliness und readiness aktualisiert
   $ helm ls # perfekt, Flux erzeugt die korrekten Helm CRDs in Kubernetes
   $ # http://apps.trutz.cloud/rolldice im Browser öffnen, um die Anwendung zu sehen

Flux Webhook-Receiver
---------------------

Erzeuge zunächst ein zufälliges Secret für den Webhook-Receiver:

.. code-block:: console

   $ TOKEN=$(head -c 12 /dev/urandom | shasum | cut -d ' ' -f1)
   $ echo $TOKEN
   $ kubectl -n flux-system create secret generic webhook-token --from-literal=token=$TOKEN
   $ kubectl -n flux-system get secrets
   $ kubectl apply -f webhook-receiver-ingress.yaml
   $ # webhook-receiver.trutz.cloud in DNS eintragen, damit die Ingress-Regel funktioniert
   $ kubectl apply -f webhook-receiver.yaml
   $ kubectl -n flux-system get receivers
   $ kubectl -n flux-system describe receiver/webhook-receiver
   $ # webhook in GitHub eintragen https://github.com/trutzio/kubernetes-tutorial/settings/hooks Achtung: Webhook Path: aus dem webhook-receiver.yaml nicht vergessen
   $ vim github-gitrepository.yaml # interval auf 12h setzen, da das Webhook die Änderungen an Git erkennt und Flux das Deployment aktualisiert
   $ kubectl apoply -f github-gitrepository.yaml