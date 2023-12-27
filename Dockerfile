FROM python:3.8-alpine

RUN mkdir /app

ADD . /app

WORKDIR /app

EXPOSE 8080

CMD ["python3", "app.py"]
