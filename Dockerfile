FROM ubuntu:20.04
RUN apt update && apt install -y python

WORKDIR /app
ADD . .

CMD ["python","test.py"]
