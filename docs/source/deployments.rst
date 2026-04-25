Kubernetes Deployments
======================

Für den weitere Verlauf des Tutorials werde ich einen Control-Plane starten. Siehe `~/kubernetes-tutorial/src/opentofu/k3s-installation/k3s-installation-single/main.tf`.

Danach werden alle Teilnehmer die Möglichkeit haben, sich mit dem Cluster zu verbinden und die folgenden Schritte durchzuführen. Es ist wichtig, dass alle Teilnehmer Zugriff auf den Cluster haben, damit sie die Übungen durchführen können.

.. code-block:: bash

    $ export IP_CONTROL_PLANE=hier_ip_addresse_des_control_planes_eintragen
    $ export K3S_TOKEN=$(ssh -i ../opentofu/schulung root@$IP_CONTROL_PLANE 'cat /var/lib/rancher/k3s/server/agent-token')
    $ curl -sfL https://get.k3s.io | K3S_URL=https://$IP_CONTROL_PLANE:6443 K3S_TOKEN=$K3S_TOKEN sh -
    $ scp -i ../opentofu/schulung root@$IP_CONTROL_PLANE:/etc/rancher/k3s/k3s.yaml ~/.kube/config
    $ vim ~/.kube/config # hier die IP-Adresse des Control-Planes eintragen, damit kubectl mit dem Cluster kommunizieren kann
    $ kubectl get nodes

Wir fangen mit den Kubernetes Grundlagen an und zwar mit einem PgAdmin4 Deployment:

.. literalinclude:: ../../src/deployments/pgadmin4-deployment.yaml

.. code-block:: bash

    $ cd ~/kubernetes-tutorial/src/deployments
    $ kubectl apply -f pgadmin4-deployment.yaml
    $ kubectl get pod -o wide
    $ kubectl get rs
    $ kubectl get deploy
    $ kubectl get all

Wie kann man nun die Applikation erreichen? Für Debugging:

.. code-block:: bash

    $ kubectl port-forward pod/pgadmin4-[id] 8080:80 --address=0.0.0.0

.. warning:: 

   `kubectl port-forward` ist nicht für die Produktion gedacht, sondern nur für Entwicklungszwecke. In einer Produktionsumgebung sollte man NIE `kubectl port-forward` verwenden!

Nun wird unser Deployment skaliert:

.. code-block:: bash

    $ kubectl scale rs/pgadmin4-[id] --replicas=2 # funktioniert nicht, da die Replikas von einem Deployment verwaltet werden
    $ kubectl get all
    $ kubectl scale deploy/pgadmin4 --replicas=2 # funktioniert, da das Deployment die Replikas verwaltet
    $ kubectl get pod -o wide

Nun können wir über Port-Forwarding beide Pods erreichen.

Services
--------

