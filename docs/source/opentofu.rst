OpenTofu
========

.. _opentofu: https://opentofu.org/

Mit OpenTofu_ kann man zum Beispiel Kubernetes-Cluster automatisiert erstellen, deren Nodes in der Cloud laufen. OpenTofu, als Open Source Branch von Terraform, bietet eine breite Unterstützung für verschiedene Cloud-Anbieter (AWS, Azure, Google Cloud, etc.) aber auch Hetzner. Die Installation von OpenTofu ist einfach, siehe https://opentofu.org/docs/intro/install/ 

In diesem Tutorrial werde ich als Dozent Tofu vorführen.

Ein sehr einfaches Beispiel für die Verwendung von OpenTofu ist die Erstellung der Schulungs-VMs bei Hetzner:

.. literalinclude:: ../../src/opentofu/schulung-vms/main.tf

Diese Datei enthält die OpenTofu-Konfiguration, um eine Anzahl von VMs zu erstellen, die für die Schulung verwendet werden können. Die Anzahl der VMs kann über die Variable `students` angepasst werden. Jede VM wird mit Debian 13 als Betriebssystem erstellt. Als Tofu-Provider wird der Hetzner-Cloud-Provider verwendet, mit dem Abschnitt `resource "hcloud_server" "student"` wird angegeben, wie die VMs aussehen sollen und wie sie initialisiert werden sollen. Eine ausführliche Dokumentation zum Hetzner-Cloud-Provider findet man unter https://search.opentofu.org/provider/opentofu/hcloud/latest.

Mit Tofu kann man natürlich auch komplette Kubernetes-Cluster erstellen. Zum Beispiel:

Installiert einen einzigen k3s Control-Plane Node, der auch die Rolle eines Worker-Nodes übernimmt.

.. literalinclude:: ../../src/opentofu/k3s-installation/k3s-installation-single/main.tf

Installiert einen k3s Cluster mit einem Control-Plane Node und n Worker-Nodes. Die Anzahl der Worker-Nodes kann über die Variable `k3s_node_count` angepasst werden.

.. literalinclude:: ../../src/opentofu/k3s-installation/k3s-installation-n-nodes/main.tf

Installiert einen hochverfügbaren k3s Cluster mit drei Control-Plane Nodes und n Worker-Nodes. Die Anzahl der Worker-Nodes kann über die Variable `k3s_node_count` angepasst werden.

.. literalinclude:: ../../src/opentofu/k3s-installation/k3s-installation-ha/main.tf

Das Zielbild einer HA-Kubernetes-Installation ist, dass die Control-Planes redundant ausgelegt sind, damit der Ausfall eines Control-Planes nicht zum Ausfall des gesamten Clusters führt. Die Mindestanzahl von Control-Planes für eine HA-Kubernetes-Installation ist drei.

.. image:: img/kubernetes-ha-architektur.svg
   :alt: HA-Kubernetes-Architektur

