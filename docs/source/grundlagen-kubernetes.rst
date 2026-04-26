Kubernetes Grundlagen
=====================

Für den weitere Verlauf des Tutorials werde ich einen Control-Plane starten. Siehe `~/kubernetes-tutorial/src/opentofu/k3s-installation/k3s-installation-single/main.tf`.

Danach werden alle Teilnehmer die Möglichkeit haben, sich mit dem Cluster zu verbinden und die folgenden Schritte durchzuführen. Es ist wichtig, dass alle Teilnehmer Zugriff auf den Cluster haben, damit sie die Übungen durchführen können.

.. code-block:: bash

    $ export IP_CONTROL_PLANE=hier_ip_addresse_des_control_planes_eintragen
    $ export K3S_TOKEN=$(ssh -i ../opentofu/schulung root@$IP_CONTROL_PLANE 'cat /var/lib/rancher/k3s/server/agent-token')
    $ curl -sfL https://get.k3s.io | K3S_URL=https://$IP_CONTROL_PLANE:6443 K3S_TOKEN=$K3S_TOKEN sh -
    $ scp -i ../opentofu/schulung root@$IP_CONTROL_PLANE:/etc/rancher/k3s/k3s.yaml ~/.kube/config
    $ vim ~/.kube/config # hier die IP-Adresse des Control-Planes eintragen, damit kubectl mit dem Cluster kommunizieren kann
    $ kubectl get nodes

Deployments
-----------

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
    $ kubectl describe statefulset/postgres

Wir wollen einen Service erstellen, um die Datenbank zu erreichen:

.. literalinclude:: ../../src/deployments/postgres-service.yaml

.. code-block:: bash

    $ kubectl apply -f postgres-service.yaml
    $ kubectl get svc
    $ kubectl describe svc/postgres
    $ kubectl port-forward svc/postgres 5432:5432 --address=0.0.0.0 # und aus einem PG Client heraus auf die Datenbank zugreifen

Nun kann man in der PgAdmin4 UI die Postgres-Datenbank einrichten und sich mit ihr verbinden.

.. code-block:: bash

    $ kubectl port-forward svc/pgadmin4 8080:9090 --address=0.0.0.0

und im Browser eine DB Verbindung in PgAdmin4 einrichten, um die Postgres-Datenbank zu erreichen. Der Hostname ist `postgres` (der Name des Services), der Port ist `5432`, der Benutzername ist `postgres` und das Passwort ist `secret`.

Nun kann man sich erneut aus Visual Studio Code mit der Postgres-Datenbank verbinden, um zu sehen, dass die Daten persistent sind:

.. code-block:: bash

    $ kubectl port-forward svc/postgres 5432:5432 --address=0.0.0.0

Was passiert aber, wenn wir der `postgres`-Pod aus dem StatefulSet gelöscht wird?

.. code-block:: bash

    $ kubectl delete pod postgres-0
    $ kubectl get pods -o wide

Der Pod wird automatisch neu erstellt, da er von einem StatefulSet verwaltet wird. Und da der Pod eine stabile Netzwerk-Identität hat, wird er immer den Namen `postgres-0` haben. Ist die Datenbanktabelle, die wir vorhin erstellt haben, immer noch da?

Persistent Volumes Claims
-------------------------

Persistent Volumes Claims (PVCs) sind eine Möglichkeit, persistenten Speicher für Pods bereitzustellen. Sie ermöglichen es, Speicher von einem Storage-Provider zu reservieren und diesen Speicher dann in einem Pod zu verwenden. 

.. literalinclude:: ../../src/deployments/postgres-pvc.yaml

.. code-block:: bash

    $ kubectl apply -f postgres-pvc.yaml
    $ kubectl get pvc
    $ kubectl describe pvc/postgres

Nun können wir den PVC in unserem StatefulSet verwenden:

.. literalinclude:: ../../src/deployments/postgres-statefulset-with-pvc.yaml

.. code-block:: bash

    $ kubectl get statefulsets
    $ kubectl delete statefulset postgres
    $ kubectl apply -f postgres-statefulset-with-pvc.yaml
    $ kubectl describe pvc/postgres
    $ kubectl get statefulsets
    $ kubectl get pods -o wide
    $ kubectl describe statefulset/postgres
    $ kubectl exec -it pod/postgres-0 -- bash
    $ psql -U postgres
    $ CREATE TABLE person (name VARCHAR(255));
    $ INSERT INTO person (name) VALUES ('Christian Trutz');
    $ SELECT * FROM person;
    $ \\q
    $ exit
    $ kubectl delete pod postgres-0
    $ kubectl get pods -o wide
    $ kubectl exec -it pod/postgres-0 -- bash
    $ psql -U postgres
    $ SELECT * FROM person;

Zu einem PVC gehört immer ein Persistent Volume (PV), das den tatsächlichen Speicher repräsentiert. In unserem Fall wird der PV automatisch von Kubernetes erstellt, da wir einen StorageClass mit dem Namen `local-path` verwenden, der standardmäßig in k3s enthalten ist. Der PV wird auf dem Node erstellt, auf dem der Pod läuft, und der Speicher wird auf dem lokalen Dateisystem des Nodes bereitgestellt.

.. code-block:: bash

    $ kubectl get pv
    $ kubectl describe pv [id pv]
    $ kubectl get pv [id pv] -o json | jq .spec.local.path
    $ ls -lah [path_aus_obigem_befehl]

ConfigMaps und Secrets
----------------------

ConfigMaps und Secrets sind Möglichkeiten, Konfigurationsdaten und sensible Daten in Kubernetes zu speichern. ConfigMaps werden für Konfigurationsdaten verwendet, Secrets für sensible Daten wie Passwörter oder API-Schlüssel verwendet werden. ConfigMaps und Secrets können in Pods als Umgebungsvariablen übergeben oder als Dateien gemountet werden.

Für unser PostgreSQL-Deployment könnten wir zum Beispiel die Konfigurationsdaten wie den Benutzernamen, die Datenbank in einer ConfigMap:

.. literalinclude:: ../../src/deployments/postgres-configmap.yaml

und das Passwort in einem Secret speichern:

.. literalinclude:: ../../src/deployments/postgres-secret.yaml

.. important:: 

   Es ist wichtig zu beachten, dass Secrets in Kubernetes nicht wirklich sicher sind, da sie Base64-kodiert und nicht verschlüsselt sind. In einer Produktionsumgebung sollten zusätzliche Sicherheitsmaßnahmen ergriffen werden, um Secrets zu schützen, wie zum Beispiel 

Ingress
-------

Ingress ist eine Möglichkeit, HTTP- und HTTPS-Verkehr zu einem Service in Kubernetes zu routen. Es ermöglicht es, mehrere Services unter derselben IP-Adresse und demselben Port zu exponieren.

.. literalinclude:: ../../src/deployments/pgadmin4-ingress.yaml

Die Ingress-Ressource definiert, dass Anfragen an `http://pgadmin4.trutz.cloud/` an den Service `pgadmin4` weitergeleitet werden sollen.

Ingress alleine reicht nicht aus, um den Verkehr zu routen. Es wird ein Ingress-Controller benötigt, der die Ingress-Ressourcen überwacht und die entsprechenden Regeln konfiguriert. In unserem Fall verwenden wir den Traefik-Ingress-Controller, der standardmäßig in k3s enthalten ist.

.. notice:: 
    Es wird natürlich vorausgesetzt, dass die DNS-Einträge für `pgadmin4.trutz.cloud` auf die IP-Adresse des Control-Planes zeigen, damit die Anfragen an den Ingress-Controller weitergeleitet werden können.

.. code-block:: bash

    $ kubectl apply -f pgadmin4-ingress.yaml
    $ kubectl get ingress
    $ kubectl describe ingress/pgadmin4
    $ http://pgadmin4.trutz.cloud/  # im Browser aufrufen

.. tip:: 

    Der Einstiegspunkt von aussen in das Cluster ist der Ingress-Controller, dessen Aufgabe ist den Verkehr zu den Services im Cluster zu routen. Das Mapping URL zu Service wird typischerweise auf Domain-Ebene gemacht, also zum Beispiel http://pgadmin4.trutz.cloud/ zum Service `pgadmin4`, aber es ist auch möglich, das Routing auf Context-Pfad-Ebene zu machen, zum Beispiel http://trutz.cloud/pgadmin4/ zum Service `pgadmin4`, aber hier ist zu beachten, dass die Applikation dann so konfiguriert sein muss, dass sie den obigen Context-Pfad unterstützt.

Kubernetes Controller und CRDs
------------------------------

Kubernetes Controller sind Prozesse, die den aktuellen Zustand des Clusters überwachen und sicherstellen, dass er dem gewünschten Zustand entspricht. Sie reagieren auf Änderungen im Cluster und führen die notwendigen Aktionen aus, um den gewünschten Zustand zu erreichen. Custom Resource Definitions (CRDs) ermöglichen es, benutzerdefinierte Ressourcen in Kubernetes zu erstellen, die von Controllern verwaltet und überwacht werden können.

.. code-block:: bash

    $ kubectl get crds
    $ kubectl describe crd [name_der_crd]
    $ kubectl api-resources


    