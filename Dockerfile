FROM debian:11-slim
WORKDIR /app
RUN apt-get update -y && \
    apt-get -y --no-install-recommends python3 python3-pip && \
    rm -rf /var/lib/apt/lists/*
COPY ./app /app    
RUN pip3 install --no-cache-dir -r requirements.txt
ENTRYPOINT [ "python3","/app/app.py" ]