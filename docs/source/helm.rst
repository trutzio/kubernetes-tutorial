Helm
====

Installation
------------

Installation durch folgende Befehle:

.. code-block:: bash

    $ sudo apt install curl gpg apt-transport-https --yes
    $ curl -fsSL https://packages.buildkite.com/helm-linux/helm-debian/gpgkey | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
    $ echo "deb [signed-by=/usr/share/keyrings/helm.gpg] https://packages.buildkite.com/helm-linux/helm-debian/any/ any main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
    $ sudo apt update
    $ sudo apt install helm

External Secrets
----------------

In Azure Key Vault können Secrets sicher gespeichert werden. Aber wie können wir diese Secrets in Kubernetes verwenden? Dafür gibt es das Projekt `External Secrets`, welches es ermöglicht, Secrets aus externen Secret-Stores wie Azure Key Vault in Kubernetes zu synchronisieren. Zunächst wird das Projekt `External Secrets <https://external-secrets.io/>`_ in Kubernetes installiert:

.. code-block:: bash

    $ kubectl apply -f "https://raw.githubusercontent.com/external-secrets/external-secrets/v2.4.0/deploy/crds/bundle.yaml" --server-side
    $ kubectl get crds | grep helm
    $ helm install external-secrets external-secrets/external-secrets -n external-secrets --create-namespace --set installCRDs=false
    $ helm -n external-secrets ls
    $ kubectl get all -n external-secrets
    $ kubectl get crds | grep externalsecrets

In Azure Key Vault wird ein Secret angelegt, welches in Kubernetes synchronisiert werden soll. Siehe https://portal.azure.com/#@trutzsoftwareconsultingde.onmicrosoft.com/resource/subscriptions/52811db6-2914-4b47-beef-04ff9f21cc21/resourceGroups/trutzio/providers/Microsoft.KeyVault/vaults/schulungk8s/overview

.. code-block:: bash

    $ vim schulungk8s-azure-secrets.yaml # hier die Azure Key Vault Client-ID und Secret-ID eintragen
    $ kubectl apply -f schulungk8s-azure-secrets.yaml
    $ kubectl apply -f schulungk8s-secret-store.yaml
    $ kubectl apply -f schulungk8s-external-secret.yaml
    $ kubectl exec pod/postgres-0 -- psql -U postgres -c "ALTER USER postgres PASSWORD 'your_secure_password' VALID UNTIL '2026-12-31';"
    $ # Passwort in Azure Key Vault ändern
    $ kubectl get externalsecret schulungk8s
    $ kubectl get secret postgres -o json | jq .data.POSTGRES_PASSWORD | tr -d "\"" | base64 -d
    $ # http://pgadmin4.trutz.cloud und Passwort aus Azure Key Vault verwenden, um sich mit der PostgreSQL-Datenbank zu verbinden

MongoDB Installation
----------------------

Es wird das MongoDB-Helm-Chart von Bitnami verwendet, um MongoDB in Kubernetes zu installieren. Siehe https://app-catalog.vmware.com/bitnami/apps

.. code-block:: bash

    $ helm registry login registry-1.docker.io/bitnamicharts # hier die Docker Hub Zugangsdaten eingeben, username: trutzio, password: [docker_pat]
    $ helm install oci://registry-1.docker.io/bitnamicharts/mongodb --version 18.6.31 --generate-name
    $ helm ls
    $ kubectl get all -l app.kubernetes.io/name=mongodb
    $ kubectl get pvc
    $ kubectl get pv
    $ kubectl get secret -l app.kubernetes.io/name=mongodb -o json | jq .items[0].data | jq 'to_entries[].value' | tr -d "\"" | base64 -d
    $ kubectl get svc -l app.kubernetes.io/name=mongodb
    $ kubectl port-forward svc/mongodb-[id] 27017:27017 --address=0.0.0.0
    $ # Neue MongoDB Connection in Visual Studio Code anlegen, Host: [ip student-x], Port: 27017, Authentication Database: admin, Username: root, Passwort: [aus_obigem_befehl]
    $ kubectl exec pod/mongodb-[id] -c mongodb -it -- bash
    $ mongosh -u root -p [aus_obigem_befehl]
    $ show dbs
    $ use admin
    $ db.system.users.find()
    $ exit
    $ exit
    $ helm ls
    $ helm uninstall [name_der_helm_release]

Eigene Anwendung
----------------

.. literalinclude:: ../../src/apps/rolldice/app.py

Eine minimale Webanwendung, die einen Würfelwurf simuliert. Die Anwendung wird als Docker-Image gebaut, siehe auch:

.. literalinclude:: ../../src/apps/rolldice/Dockerfile

.. code-block:: bash

    $ cd ~/src/apps/rolldice/helm
    $ helm template rolldice/
    $ helm install rolldice/ --generate-name
    $ helm ls
    $ kubectl get all -l app.kubernetes.io/name=rolldice
    $ kubectl logs -l app.kubernetes.io/name=rolldice # pod ist nicht erreichbar, da kein Liveliness und Readiness Probe definiert ist
    $ vim rolldice/Chart.yaml # appVersion von 1.0.0 auf 1.0.1 ändern, da Liveliness und Readiness Probe hinzugefügt wurden
    $ helm ls
    $ helm upgrade rolldice-[generierte id] rolldice/
    $ kubectl get all -l app.kubernetes.io/name=rolldice
    $ kubectl logs -f -l app.kubernetes.io/name=rolldice
    $ # http://apps.trutz.cloud/rolldice im Browser öffnen, um die Anwendung zu testen
    
Pipelines mit GitHub Actions
----------------------------

In GitHub Actions wird eine Pipeline definiert, die die Anwendung baut, das Docker-Image in Docker Hub pusht.

.. literalinclude:: ../../.github/workflows/docker-image.yml

.. code-block:: bash

    $ # In GitHub Repository Settings -> Secrets -> Actions die folgenden Secrets anlegen:
    $ # DOCKER_USERNAME: trutzio
    $ # DOCKER_PASSWORD: [docker_pat]
    $ git tag v1.0.0
    $ git push origin v1.0.0