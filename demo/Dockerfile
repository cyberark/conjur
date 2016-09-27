FROM ubuntu:14.04

RUN apt-get update -y && apt-get install -y git curl vim python-pip

RUN git clone https://github.com/conjurinc/api-python /app

WORKDIR /app
ENV PYTHONPATH /app

RUN git checkout work/possum
RUN pip install -r requirements.txt -r requirements_dev.txt
