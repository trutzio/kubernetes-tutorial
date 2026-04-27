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

.. literalinclude:: ../../src/flux/github-gitrepository.yaml

Das folgende HelmRelease-Manifest definiert das Deployment der Rolldice-Anwendung über Flux.

.. literalinclude:: ../../src/flux/helm/rolldice-helmrelease.yaml
   
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
   $ kubectl apply -f github-gitrepository.yaml
   $ # Änderung in Git im Helm Chart vornehmen, z.B. die appVersion in Chart.yaml auf 1.0.4 erhöhen

Trennung von Infrastruktur und Anwendung
----------------------------------------

In diesem Tutorial wurde die Infrastruktur der Anwendung (Helm-Skript) und die Anwendung selbst im selber Git-Repository gespeichert. In der Praxis ist es jedoch üblich, die Infrastruktur und die Anwendung in getrennten Git-Repositories zu speichern. Dies ermöglicht eine bessere Trennung von Verantwortlichkeiten und erleichtert die Verwaltung der Infrastruktur und der Anwendung.

Eine mögliche Struktur könnte wie folgt in einem einzigen Git-Repository aussehen:

.. code-block:: console

   ├── develop
   │   ├── integration (Entwicklungsumgebung)
   │   │   ├── app1    (Helm Chart für App1)
   │   │   ├── app2
   │   │   └── app3
   │   ├── testing     (Testumgebung für Tester)
   │   │   ├── app1
   │   │   ├── app2
   │   │   └── app3
   │   └── maintenance (Wartungsumgebung, Kopie der Produktionsumgebung)
   │       ├── app1
   │       ├── app2
   │       └── app3
   ├── uat             (User Acceptance Testing, Abnahmeumgebung)
   │    └─ default
   │       ├── app1
   │       ├── app2
   │       └── app3
   └── production      (Heilige Produktionsumgebung)
       └── default
           ├── app1
           ├── app2
           └── app3

In diesem Beispiel könnten `develop`, `uat` und `production` jeweils ein eigener Kubernetes-Cluster sein. Die Trennung zwischen `integration`, `testing` und `maintenance` innerhalb des develop-Clusters könnte auf Namespace-Ebene erfolgen, um verschiedene Umgebungen innerhalb desselben Clusters zu haben.

Das Ziel sollte sein, die Infrastruktur (Helm-Charts) auf allen Ebene gleich aussehen zu lassen (gleiche Helm Templates), die Unterschiede zwischen den Umgebungen sollten nur in den Werten (values.yaml) liegen, damit die Wartung der Infrastruktur einfacher wird. Man kann dann mit Git-Mitteln wie Branches, Pull Requests und Merge-Strategien arbeiten, um Änderungen an der Infrastruktur zu verwalten und sicherzustellen, dass sie ordnungsgemäß getestet und genehmigt werden, bevor sie in die Produktionsumgebung gelangen.

Beispiel: `app1` wird auf der `develop/integration`-Umgebung entwickelt und auf Git-Push-basis in diese Umgebung via Pipelines deployed. Am Ende eines Sprints wird die `app1`-Anwendung in die `develop/testing`-Umgebung überführt und von den Testern getestet. Nach erfolgreichem Testen wird die `app1`-Anwendung in die `uat/default`-Umgebung überführt auf der sie die Abnahme erfolgt, z.B. durch das Testen des Product Owners oder durch die Enduser. Nach erfolgreicher Abnahme wird die `app1`-Anwendung in die `production/default`-Umgebung überführt und ist für die Enduser verfügbar. Gleichzeitig wird die `app1`-Anwendung in der `develop/maintenance`-Umgebung bereitgestellt, damit die Entwickler eine Wartungsumgebung haben für Hotfixes auf der Produktion.

Git Branches
------------

Die Git-Branches der Anwendung (nicht der Infrastruktur) könnten wie folgt aussehen:

#. Branch `develop` entspricht der `develop/integration`-Umgebung, hier wird die Anwendung entwickelt und auf Git-Push-Basis in die `develop/integration`-Umgebung deployed
#. Branch `release/v1.4` entspricht der `develop/testing`-Umgebung, hier werden die Änderungen von den Testern getestet
#. Tag `v1.4.4` entspricht der `uat/default`-Umgebung, hier erfolgt die Abnahme durch den Product Owner oder die Enduser
#. Tag `v1.4.4` und `main`-Branch entsprechen der `production/default`-Umgebung, hier ist die Anwendung deployed nach erfolgreicher Abnahme
#. Branch `hotfix/v1.4.5` entspricht der `develop/maintenance`-Umgebung, hier werden Hotfixes auf der Produktion entwickelt, dieser Branch wird aus dem `main`-Branch abgezweigt