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
    $ helm install external-secrets external-secrets/external-secrets -n external-secrets --create-namespace --set installCRDs=false
    $ kubectl get all -n external-secrets
    $ kubectl get crds | grep externalsecrets

In Azure Key Vault wird ein Secret angelegt, welches in Kubernetes synchronisiert werden soll. Siehe https://portal.azure.com/#@trutzsoftwareconsultingde.onmicrosoft.com/resource/subscriptions/52811db6-2914-4b47-beef-04ff9f21cc21/resourceGroups/trutzio/providers/Microsoft.KeyVault/vaults/schulungk8s/overview

.. code-block:: bash

    $ vim schulungk8s-azure-secrets.yaml # hier die Azure Key Vault Client-ID und Secret-ID eintragen
    $ kubectl apply -f schulungk8s-azure-secrets.yaml
    $ kubectl apply -f schulungk8s-secret-store.yaml
    $ kubectl apply -f schulungk8s-external-secret.yaml