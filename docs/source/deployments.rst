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

Services ermöglichen es, eine Gruppe von Pods als einen einzigen Dienst zu exponieren. Sie ermöglichen es, den Zugriff auf die Pods zu load-balancen.

.. literalinclude:: ../../src/deployments/pgadmin4-service.yaml

.. code-block:: bash

    $ kubectl apply -f pgadmin4-service.yaml
    $ kubectl get svc
    $ kubectl port-forward svc/pgadmin4 8080:9090 --address=0.0.0.0 # und im Browser aufrufen
    $ kubectl describe svc/pgadmin4
    $ kubectl get endpoints pgadmin4
    $ kubectl get endpointslices

.. notice :: 

   Session Affinity mit `ClientIP` sorgt dafür, dass Anfragen von einem bestimmten Client immer an denselben Pod weitergeleitet werden. ABER die IP Adresse kann sich ändern, was zu Problemen führen kann. In einer Produktionsumgebung sollte man daher vorsichtig mit der Verwendung von Session Affinity auf Basis von IP-Adressen sein (Kubernetes Services). Besser ist es Session Affinity auf Basis von Cookies zu verwenden, wenn die Anwendung dies unterstützt.

StatefulSets
------------

StatefulSets sind sehr ähnlich zu Deployments, aber sie sind für Anwendungen gedacht, die einen stabilen Netzwerk-Identität und persistenten Speicher benötigen. Sie werden oft für Datenbanken verwendet. Wir wollen nun eine PostgreSQL-Datenbank mit einem StatefulSet deployen:

.. literalinclude:: ../../src/deployments/postgres-statefulset.yaml

.. code-block:: bash

    $ kubectl apply -f postgres-statefulset.yaml
    $ kubectl get statefulsets
    $ kubectl get pods -o wide