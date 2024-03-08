FROM python:3.11-alpine

RUN apk update 

COPY *.py /
ENTRYPOINT ["/entrypoint.py"]
