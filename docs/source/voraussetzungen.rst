Voraussetzungen
===============

.. _voraussetzungen:
.. _opentofu: https://opentofu.org/docs/intro/install/

Folgende Kenntnisse werden in diesem Tutorial vorausgesetzt:

#. grundlegende Kenntnisse in Umgang mit Linux, zum Beispiel Berechtigungen von Dateien, Verzeichnisstrukturen,
#. Umgang mit der Kommandozeile (PowerShell, Bash), 
#. grundlegende Netzwerkkonzepten, wie IP-Adressen, Ports und Firewalls,

Folgende Software wird für die Durchführung dieses Tutorials benötigt:

#. `bash` oder `PowerShell` als Kommandozeile
#. `docker` zum Ausführen von Containern
#. `kubectl` zum Verwalten von Kubernetes-Clustern
#. `ssh-keygen` zum Erstellen von SSH-Schlüsseln, erzeuge einen SSH Key mit `ssh-keygen -t ed25519 -f schulung` und lade den Public-Anteil des Keys `schulung.pub` bei Hetzner unter "Security > SSH keys" hoch
#. `opentofu`_ zum Bereitstellen von Infrastruktur in der Hetzner Cloud
#. Umgebungsvariable `TF_VAR_hcloud_token_schulungen` enthält den Hetzner API Token