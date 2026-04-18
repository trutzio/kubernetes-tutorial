Installation
============

.. _installation:
.. _kind: https://kind.sigs.k8s.io/
.. _k3s: https://k3s.io/

In diesem Abschnitt werden wir zwei wichtige Kubernetes-Distributionen installieren:

#. `kind`_ oder Kubernetes in Docker, geeignet für lokale Entwicklungs- und Testumgebungen und
#. `k3s`_ eine leichtgewichtige Distribution, gut geeignet um Kubernetes zu lernen aber auch für produktive Umgebungen.

kind - Kubernetes in Docker
---------------------------

`kind`_ ist eine Kubernetes-Distribution, die innerhalb von Docker Containern läuft. Sie ist eine gute Option für die lokale Entwicklung und das Testen von Kubernetes-Anwendungen, da sie einfach zu installieren und zu verwenden ist:

Installation unter Linux:

.. code-block:: console

   $ curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.31.0/kind-linux-amd64
   $ chmod +x ./kind
   $ sudo mv ./kind /usr/local/bin/

Installation unter Windows (Powershell):

.. code-block:: console

   $ curl.exe -Lo kind-windows-amd64.exe https://kind.sigs.k8s.io/dl/v0.31.0/kind-windows-amd64
   $ Move-Item .\kind-windows-amd64.exe c:\some-dir-in-your-PATH\kind.exe

.. seealso::

   Weitetere Möglichkeiten zur Installation von `kind`_ findet ihr in der offiziellen `Installationsdokumentation <https://kind.sigs.k8s.io/docs/user/quick-start/#installation>`_.

