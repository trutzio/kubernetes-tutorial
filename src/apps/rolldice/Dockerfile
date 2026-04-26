FROM python:3.13.13-slim-trixie

ADD requirements.txt /tmp/requirements.txt
RUN pip install -r /tmp/requirements.txt

RUN mkdir -p /app
ADD app.py /app
WORKDIR /app

CMD ["flask", "run", "--host=0.0.0.0", "--port=80"]