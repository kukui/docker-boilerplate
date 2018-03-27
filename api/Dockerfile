FROM python:3.6.4-stretch
MAINTAINER Kai Keliikuli
RUN apt-get update -y
RUN apt-get install -y postgresql-client netcat python3-pip python3-dev ipython3 build-essential git
RUN pip3 install --upgrade pip
WORKDIR /api
COPY . /api
RUN pip3 install -r requirements.txt
CMD ["tail", "-f", "/dev/null"]
