Monitoring
==========

Open Telemetry (OTEL)
---------------------

Open Telemetry (OTEL) ist ein Open-Source-Projekt, das eine Sammlung von Tools, APIs und SDKs bereitstellt, um Telemetrie-Daten wie Metriken, Logs und Traces zu sammeln und zu exportieren. OTEL ermöglicht es Entwicklern, Einblicke in die Leistung und das Verhalten ihrer Anwendungen zu gewinnen, indem es eine standardisierte Möglichkeit bietet, Telemetrie-Daten zu erfassen und zu exportieren. OTEL definiert die API, an die sich dann die verschiedenen OTEL-Implementierungen halten müssen. Zum Beispiel gibt es für 

#. OTEL-Traces `Jaeger <https://www.jaegertracing.io/>`_, `Zipkin <https://zipkin.io/>`_ und `Tempo <https://grafana.com/oss/tempo/>`_ für
#. OTEL-Metriken `Prometheus <https://prometheus.io/>`_ und `Grafana Mimir <https://grafana.com/oss/mimir/>`_ für
#. OTEL-Logs `Loki <https://grafana.com/oss/loki/>`_ 

Grafana mit Docker Compose
--------------------------

.. code-block:: console

    $ cd ~/kubernetes-tutorial/src/docker/monitoring/
    $ docker compose up -d
    $ # http://[ip student-x]:3000
    $ cd ~/kubernetes-tutorial/src/apps/rolldice/
    $ source .venv/bin/activate
    $ pip install -r requirements.txt
    $ opentelemetry-bootstrap -a install
    $ opentelemetry-instrument --service_name dice-server flask run -p 8080 -h 0.0.0.0

Grafana Cloud
-------------

Grafana Cloud ist eine vollständig verwaltete OTEL-Plattform, die Metriken, Logs und Traces iunterstützt. Der Vorteil von Grafana Cloud ist, dass die Verwaltung von Grafana und den Datenbanken hinter Grafana entfällt.

Grafana Cloud kann über https://grafana.com/orgs/trutzonline/stacks/880493 verwaltet werden, hier kann man die Daten für die OTEL-Integration einsehen. Für den Zugriff auf Grafana benötigt man einen Account (z.B. 880493) und ein Token, dass man über den obigen Link generieren kann. Das Token muss in der Umgebungsvariable ``OTEL_EXPORTER_OTLP_HEADERS`` hinterlegt werden im Format ""Authorization=Basic base64({account}:{token})" und wird als HTTP Header an den OTLP-Gateway gesendet. Neben Account und Token muss der Endpoint für den OTLP-Gateway in die Umgebungsvariable ``OTEL_EXPORTER_OTLP_ENDPOINT`` hinterlegt werden, z.B. https://otlp-gateway-prod-eu-west-2.grafana.net/otlp. Grafana Cloud unterstützt die Protokolle HTTP/Protobuf und gRPC, in diesem Beispiel verwenden wir HTTP/Protobuf, da es von Python besser unterstützt wird: also `OTEL_EXPORTER_OTLP_PROTOCOL="http/protobuf"`.

.. code-block:: console

    $ export OTEL_EXPORTER_OTLP_PROTOCOL="http/protobuf"
    $ export OTEL_EXPORTER_OTLP_ENDPOINT="https://otlp-gateway-prod-eu-west-2.grafana.net/otlp"
    $ # Python requires "Basic%20" instead of "Basic "
    $ export OTEL_EXPORTER_OTLP_HEADERS="Authorization=Basic%20base64(880493:token)"
    $ opentelemetry-instrument --service_name dice-server flask run -p 8080 -h 0.0.0.0

Aufgabe
-------

Verändere das Helm-Skript der diceroll-App so, dass die OTEL-Umgebungsvariablen für Grafana Cloud gesetzt werden und die App die Traces an Grafana Cloud sendet. Überprüfe, ob die Traces in Grafana Cloud ankommen.


Kubernetes-Cluster Logs
-----------------------

In Kubernetes-Cluster können Logs von verschiedenen Komponenten wie Pods/Containern, Nodes usw. generiert werden. Man kann die Logs clusterweit an Loki senden, siehe zum Beispiel https://grafana.com/orgs/trutzonline/hosted-logs/838274#sending-logs.

Mit dem obigen Skript wird im Kubernetes-Cluster ein DaemonSet erstellt, der die Logs von allen Nodes sammelt und an Loki sendet. Die Logs können dann in Grafana Cloud angeschaut werden. Ein Kubernetes DaemonSet allgemein installiert einen Pod auf jedem Node im Cluster und wird typischerweise für Dienste in Kubernetes verwendet, die auf jedem Node laufen müssen, wie z.B. Log-Sammler.


Grafana Alerts
--------------

Erzeuge einen Alert in Grafana, der ausgelöst wird, wenn die Anzahl der 404-Fehler in den letzten 5 Minuten für die diceroll-App über 0 liegt. Verwendet wird dafür die folgende PromQL-Abfrage:

.. code-block:: console

    $ count_over_time({namespace="default", service_name="rolldice"} |= `404` [5m])

Behebe nun das Problem, das die 404-Fehler verursacht, und überprüfe, ob der Alert in Grafana ausgelöst wird.