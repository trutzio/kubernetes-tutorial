OpenTofu
========

.. _opentofu: https://opentofu.org/
.. _etcd: https://www.cncf.io/projects/etcd/
.. _haproxy: https://www.haproxy.org/

Mit OpenTofu_ kann man zum Beispiel Kubernetes-Cluster automatisiert erstellen. OpenTofu, als Open Source Branch von Terraform, bietet eine breite Unterstützung für verschiedene Cloud-Anbieter (AWS, Azure, Google Cloud, etc.) aber auch Hetzner. Die Installation von OpenTofu ist einfach, siehe https://opentofu.org/docs/intro/install/ 

.. code-block:: bash

   $ curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh -o install-opentofu.sh
   $ chmod +x install-opentofu.sh
   $ ./install-opentofu.sh --install-method deb
   $ rm -f install-opentofu.sh
   $ tofu --version

In diesem Tutorrial werde ich alleine als Dozent Tofu vorführen. Ein sehr einfaches Beispiel für die Verwendung von OpenTofu ist die Erstellung der Schulungs-VMs bei Hetzner:

.. literalinclude:: ../../src/opentofu/schulung-vms/main.tf

Diese Datei enthält die OpenTofu-Konfiguration, um eine Anzahl von VMs zu erstellen, die für die Schulung verwendet werden können. Die Anzahl der VMs kann über die Variable `students` angepasst werden. Jede VM wird mit Debian 13 als Betriebssystem erstellt. Als Tofu-Provider wird der Hetzner-Cloud-Provider verwendet, mit dem Abschnitt `resource "hcloud_server" "student"` wird angegeben, wie die VMs aussehen sollen und wie sie initialisiert werden sollen. Eine ausführliche Dokumentation zum Hetzner-Cloud-Provider findet man unter https://search.opentofu.org/provider/opentofu/hcloud/latest.

.. code-block:: bash

   $ export HCLOUD_TOKEN=[your-hetzner-cloud-api-token]
   $ cp schulung.* ~/kubernetes-tutorial/src/opentofu # remote
   $ cd ~/kubernetes-tutorial/src/opentofu
   $ chown go-r schulung
   $ cd schulung-vms
   $ tofu init
   $ tofu plan
   $ cp terraform.tfstate ~/kubernetes-tutorial/src/opentofu/schulung-vms/terraform.tfstate # remote
   $ tofu plan -var students=8
   $ tofu apply -var students=8
   
In diesem Beispiel wird der State lokal in der Datei `terraform.tfstate` gespeichert. Es ist jedoch auch möglich, den State remote zu speichern, zum Beispiel in einem S3-Bucket oder in einem Git-Repository. Weitere Informationen zum Thema Remote State: https://opentofu.org/docs/language/state/remote/

Mit Tofu kann man natürlich auch komplette Kubernetes-Cluster erstellen.

Single Control-Plane
--------------------

Installiert einen einzigen k3s Control-Plane Node, der auch die Rolle eines Worker-Nodes übernimmt.

.. literalinclude:: ../../src/opentofu/k3s-installation/k3s-installation-single/main.tf

.. code-block:: bash

   $ cd ~/kubernetes-tutorial/src/opentofu/k3s-installation/k3s-installation-single
   $ tofu init
   $ tofu plan
   $ tofu apply
   $ tofu state list
   $ tofu state show hcloud_server.k3s-single-control-plane
   $ tofu state show hcloud_server.k3s-single-control-plane | grep "ipv4_address"
   $ ssh -i ../../schulung root@[ip control-plane]
   $ kubectl get nodes
   $ exit
   $ mkdir -p ~/.kube
   $ scp -i ../../schulung root@[ip control-plane]:/etc/rancher/k3s/k3s.yaml ~/.kube/config
   $ kubectl get nodes # error: The connection to the server 127.0.0.1:6443 was refused
   $ vim ~/.kube/config # change server: https://[IP control-plane]:6443
   $ kubectl get nodes
   $ tofu destroy


Control-Plane mit n Worker-Nodes
--------------------------------

Installiert einen k3s Cluster mit einem Control-Plane Node und n Worker-Nodes. Die Anzahl der Worker-Nodes kann über die Variable `k3s_node_count` angepasst werden.

.. literalinclude:: ../../src/opentofu/k3s-installation/k3s-installation-n-nodes/main.tf

HA Kubernetes-Installation
--------------------------

Installiert einen hochverfügbaren k3s Cluster mit drei Control-Plane Nodes und n Worker-Nodes. Die Anzahl der Worker-Nodes kann über die Variable `k3s_node_count` angepasst werden.

.. literalinclude:: ../../src/opentofu/k3s-installation/k3s-installation-ha/main.tf

Load Balancer
-------------

Das Zielbild einer HA-Kubernetes-Installation ist, dass die Control-Planes redundant ausgelegt sind, damit der Ausfall eines Control-Planes nicht zum Ausfall des gesamten Clusters führt. Die Mindestanzahl von Control-Planes für eine HA-Kubernetes-Installation ist drei.

.. image:: img/kubernetes-ha-installation.svg
   :alt: HA Kubernetes Installation

Der State eines Kubernetes-Clusters mit drei Control-Planes wird in einer replizierten `etcd`_ Datenbank gespeichert.

Die Control-Planes sind über einen Load Balancer erreichbar, der die Anfragen an die Control-Planes weiterleitet. In diesem Beispiel wird `HAProxy`_ als Load Balancer verwendet, der auf einem separaten Server installiert ist.

.. literalinclude:: ../../src/opentofu/k3s-installation/k3s-installation-ha-load-balancer/main.tf

.. code-block:: bash

   $ cd ~/kubernetes-tutorial/src/opentofu/k3s-installation/k3s-installation-ha-load-balancer
   $ tofu init
   $ tofu plan
   $ tofu apply
   $ tofu state list
   $ tofu state show hcloud_server.master-0 | grep "ipv4_address"
   $ ssh -i ../../schulung root@[ip master-0]
   $ kubectl get nodes
   $ exit
   $ tofu state show hcloud_server.load-balancer | grep "ipv4_address"
   $ ssh -i ../../schulung root@[ip load-balancer]
   $ systemctl status haproxy
   $ ls -lah /etc/haproxy/haproxy.cfg
   $ exit
   $ scp -i ../../schulung haproxy.cfg root@[ip load-balancer]:/etc/haproxy/haproxy.cfg
   $ ssh -i ../../schulung root@[ip load-balancer]
   $ vim /etc/haproxy/haproxy.cfg # change server master-0, master-1, master-2 to the IPs of the Control-Planes
   $ systemctl restart haproxy
   
Nun kann im Browser mit http://[ip load-balancer]/healthz überprüft werden, dass der Load Balancer healthy ist.

.. code-block:: bash

   $ tofu state show hcloud_server.master-0 | grep "ipv4_address"
   $ scp -i ../../schulung root@[ip master-0]:/etc/rancher/k3s/k3s.yaml ~/.kube/config
   $ vim ~/.kube/config # change server: https://[master-0]:6443
   $ kubectl get nodes
   $ vim ~/.kube/config # change server: https://[master-1]:6443
   $ kubectl get nodes
   $ vim ~/.kube/config # change server: https://[load-balancer]:6443
   $ kubectl get nodes

.. important:: 

Bitte beachte in der Tofu-Konfiguration des HA-Kubernetes-Clusters den `--tls-san ${hcloud_server.load-balancer.ipv4_address}` Eintrag. Dieser Eintrag ist notwendig, damit die Kubernetes API über die IP-Adresse des Load Balancers erreichbar ist. Die IP Adresse des Load Balancers muss in den TLS-SAN Eintrag des Clusters aufgenommen werden. Ohne diesen Eintrag würde die Kubernetes API nur über die IP-Adressen der Control-Planes erreichbar sein.

.. question::

   Was passiert eigentlich, wenn der Load Balancer ausfällt? Ist der Cluster dann nicht mehr erreichbar? Jain, der Cluster ist weiterhin erreichbar über die Control-Planes, aber es gibt keine Redundanz mehr, da der Load Balancer ausgefallen ist.

.. code-block:: bash

   $ tofu destroy

Virtuelle IP-Adresse
--------------------

Wird über den VRRP/IP Protokoll erreicht, siehe dazu auch https://de.wikipedia.org/wiki/Virtual_Router_Redundancy_Protocol. Das Tool, das VRRP/IP implementiert ist `keepalived`, siehe https://www.keepalived.org/.

Ein MASTER-Load-Balancer und ein BACKUP-LB werden installiert. Der MASTER-LB übernimmt die virtuelle IP-Adresse und sendet regelmäßig Heartbeats an den BACKUP-LB. Wenn der MASTER-LB ausfällt, übernimmt der BACKUP-LB die virtuelle IP-Adresse und sorgt dafür, dass der Cluster weiterhin erreichbar ist.

.. literalinclude:: ../../src/opentofu/k3s-installation/k3s-keepalived/main.tf

.. code-block:: bash

   $ cd ~/kubernetes-tutorial/src/opentofu/k3s-installation/k3s-keepalived
   $ tofu init
   $ tofu plan
   $ tofu apply
   $ tofu state list
   $ tofu state show 'hcloud_server.lb["0"]' | grep "ipv4_address"
   $ scp -i ../../schulung keepalived-master.conf root@[ip lb-0]:/etc/keepalived/keepalived.conf
   $ ssh -i ../../schulung root@[ip lb-0]
   $ systemctl status keepalived
   $ systemctl restart keepalived
   $ systemctl status keepalived
   $ tcpdump proto 112