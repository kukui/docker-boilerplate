FROM python:3.6

RUN apt-get update && apt-get install -y \
		postgresql-client libpq-dev \
		sqlite3 \
	--no-install-recommends && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN mkdir /djapi
RUN mkdir /djapi/static
WORKDIR /djapi

COPY requirements.txt /djapi
RUN pip install --upgrade pip
RUN pip install -r requirements.txt

COPY . /djapi

EXPOSE 8000
CMD ["./entrypoint.sh"]
