Installation Kubernetes
=======================

.. _kind: https://kind.sigs.k8s.io/
.. _k3s: https://k3s.io/

In diesem Abschnitt werden wir zwei Kubernetes-Distributionen installieren:

#. `kind`_ oder Kubernetes in Docker, geeignet für lokale Entwicklungs- und Testumgebungen und
#. `k3s`_ eine leichtgewichtige Distribution, gut geeignet um Kubernetes zu lernen aber auch für produktive Umgebungen.

kind - Kubernetes in Docker
---------------------------

`kind`_ ist eine Kubernetes-Distribution, die innerhalb von Docker Containern läuft. Sie ist eine gute Option für die lokale Entwicklung und das Testen von Kubernetes-Anwendungen, da sie einfach zu installieren und zu verwenden ist:

Installation unter Linux:

.. code-block:: console

   $ curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.31.0/kind-linux-amd64
   $ chmod +x ./kind
   $ mv ./kind /usr/local/bin/

Installation unter Windows (Powershell):

.. code-block:: console

   $ curl.exe -Lo kind-windows-amd64.exe https://kind.sigs.k8s.io/dl/v0.31.0/kind-windows-amd64
   $ Move-Item .\\kind-windows-amd64.exe C:\\some-dir-in-your-PATH\\kind.exe

.. seealso::

   Weitetere Möglichkeiten zur Installation von `kind`_ findet ihr in der offiziellen `Installationsdokumentation <https://kind.sigs.k8s.io/docs/user/quick-start/#installation>`_.

Die Erstellung eines Kubernetes-Clusters mit `kind`_ ist sehr einfach:

.. code-block:: console

   $ kind create cluster

.. error::

   Falls der der obige Befehl fehlschlägt, könnte es daran liegen, dass Docker nicht installiert oder nicht gestartet ist. `kind`_ benötigt Docker, um die Container zu erstellen, in denen die Kubernetes-Nodes laufen.

Nach dem Erstellen des Clusters wird automatisch eine `KUBECONFIG`-Datei erstellt, die die notwendigen Informationen enthält, um mit dem Cluster zu kommunizieren. Diese Datei wird im Verzeichnis `~/.kube/config` gespeichert. Der Ort aus dem diese Konfigurationsdatei geladen wird, kann mit der Umgebungsvariable `KUBECONFIG` überschrieben werden.



Nun benötigen wir die Kubernetes-CLI `kubectl`, um mit unserem `kind`_-Cluster zu kommunizieren. `kubectl`_ ist das zentrale Administrationstool für Kubernetes über die Kommandozeile:

.. code-block:: console

   $ apt-get install -y apt-transport-https ca-certificates curl gnupg
   $ curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.36/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
   $ echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.36/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list
   $ apt-get update
   $ apt-get install -y kubectl
   $ kubectl version --client

Die offizielle Dokumentation zur `kubectl`-Installation finder man unter https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/#install-using-native-package-management.

Mit dem Befehl Befehl:

.. code-block:: console

   $ kubectl config get-contexts
   CURRENT   NAME        CLUSTER     AUTHINFO                   NAMESPACE
   *         kind-kind   kind-kind   kind-kind
         
können die verfügbaren Kubernetes-Kontexte aufgelistet werden, die in der `~/.kube/config` gespeichert sind. In diesem Fall gibt es nur einen Kontext namens `kind-kind`, der automatisch von `kind`_ erstellt wurde. Dieser Kontext enthält die Informationen, die benötigt werden, um mit dem `kind`_-Cluster zu kommunizieren.

Mit dem folgenden Befehl kann man die Nodes des Clusters auflisten:

.. code-block:: console

   $ kubectl get nodes
   NAME                 STATUS   ROLES           AGE   VERSION
   kind-control-plane   Ready    control-plane   24h   v1.35.0

und erhält natürlich nur einen einzigen Node, der sowohl die Rolle des Control-Planes als auch die Rolle eines Worker-Nodes übernimmt.

Mit `kind`_ erhält man eine Kubernetes-Installation, die für die lokale Entwicklung und das Testen von Anwendungen geeignet ist, da sie sehr einfach zu installieren ist und in Docker Container läuft. Es ist jedoch wichtig zu beachten, dass `kind`_ nicht für den produktiven Einsatz gedacht ist. Mit

.. code-block:: console

   $ docker container ls
   
Sieht man, dass `kind`_ tatsächlich Docker-Container verwendet und jeder Node in einem eigenen Container läuft.

Mit dem folgenden Befehl kann ein Cluster wieder entfernt werden:

.. code-block:: console

   $ kind delete cluster
   Deleting cluster "kind" ...
   Deleted nodes: ["kind-control-plane"]

Mit dem Aufruf

.. code-block:: console

   $ kind create cluster --config ~/kubernetes-tutorial/src/kind/kind-cluster-config.yaml

und folgender Konfiguration in der Datei `kind-cluster-config.yaml`:

.. literalinclude:: ../../src/kind/kind-cluster-config.yaml
   
wird ein `kind`_-Cluster mit einem Control-Plane-Node und zwei Worker-Nodes erstellt. Dies sieht man sofort mit dem `docker`-Befehl:

.. code-block:: console

   $ docker container ls --format "table {{.Image}}\t{{.Names}}\t{{.Ports}}"
   IMAGE                  NAMES                PORTS
   kindest/node:v1.35.0   kind-control-plane   127.0.0.1:39107->6443/tcp
   kindest/node:v1.35.0   kind-worker2         
   kindest/node:v1.35.0   kind-worker

Beachte auch, dass der Port 6443 des Control-Plane-Containers auf den Port 39107 des Host-Systems weitergeleitet wird, was es ermöglicht, von außerhalb des Docker-Containers mit dem Kubernetes-API-Server zu kommunizieren. Dieser Port wurde auch in der `.kube/config`-Datei eingetragen, siehe:

.. code-block:: console

   $ cat ~/.kube/config | yq .clusters[].cluster.server

.. tip::

   `yq` ist ein praktisches Kommandozeilen-Tool, um YAML-Dateien zu filtern und zu ändern. Es kann mit `apt install yq` installiert werden. `yq` ist in der Schulungs VM bereits vorinstalliert.

Insgesamt haben wir mit `kind`_ folgenden Cluster aufgebaut:

.. image:: img/kind-cluster.svg
   :align: center
   :alt: kind Cluster


k3s - die leichtgewichtige Kubernetes-Distribution
--------------------------------------------------

`k3s`_ ist eine leichtgewichtige Kubernetes-Distribution. Sie ist eine gute Option für das Lernen von Kubernetes, da sie einfach zu installieren und zu verwenden ist. In der minimalen Konfiguration benötigt `k3s`_ 2 CPUs und 4 GB RAM, was es auch für kleinere Server oder virtuelle Maschinen geeignet macht.

Wir installieren nun die `k3s`_-Kubernetes-Distribution auf einem Debian 13 Linux Server. Dabei benötigst du root-Zugriff auf diesem Server, um die Installation durchzuführen. Logge dich zum Beispiel mit `ssh -i schulung root@[ip]` auf ein Debian 13 Server ein oder öffne mit `sudo bash` eine Root-Shell auf einem Server, auf dem du schon Zugriff hast.

.. note::
      Unter Windows kann man mit `wsl --install Debian` eine Debian 13 Distribution installieren und dann mit `wsl -d Debian` eine Bash öffnen. Vergiss nicht `sudo bash` anschliessen einzugeben, um root-Rechte zu erhalten.

Bist du nun root auf einem Debian 13 Server, kannst du `k3s`_ mit dem folgenden Befehl installieren:

.. code-block:: console

   $ curl -sfL https://get.k3s.io | sh -


.. note::

   Die Deinstallation von `k3s`_ wird mit dem Befehl `k3s-uninstall.sh` durchgeführt.

Mit dem folgenden Befehl kannst du die Nodes des Clusters auflisten:

.. code-block:: console

   $ kubectl get nodes
   NAME                STATUS   ROLES           AGE   VERSION
   debian-4gb-nbg1-1   Ready    control-plane   18s   v1.34.6+k3s1

Ziel dieser k3s Installation
----------------------------

.. image:: img/kubernetes-ha-installation.svg
   :align: center
   :alt: Kubernetes HA Installation

Cluster mit n Nodes
-------------------

HA-Cluster
----------

HA-Cluster mit Load-Balancer
----------------------------

Load-Balancer Konfiguration:

.. code-block:: console

   frontend healthz
      bind :80
      mode http
      monitor-uri /healthz

   frontend k3s-frontend
      bind :6443
      default_backend k3s-backend

   backend k3s-backend
      balance roundrobin
      server k3s-single-control-plane [ip master-0]:6443 check
      server k3s-single-control-plane [ip master-1]:6443 check
      server k3s-single-control-plane [ip master-2]:6443 check
