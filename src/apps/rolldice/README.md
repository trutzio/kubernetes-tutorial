## Installation

```
apt install python3.13-venv
python3 -m venv .venv
source ./venv/bin/activate
pip install -r requirements.txt
flask run -p 8080 -h 0.0.0.0
curl http://localhost:8080/rolldice # alternativ im Browser

export APP_VERSION=1.0.0
docker buildx build -t trutzio/rolldice:$APP_VERSION .
docker login -u trutzio
docker push trutzio/rolldice:$APP_VERSION
```

## Open Telemetry

```
opentelemetry-bootstrap -a install
opentelemetry-instrument --traces_exporter otlp --metrics_exporter otlp --logs_exporter otlp --service_name dice-server flask run -p 8080
```