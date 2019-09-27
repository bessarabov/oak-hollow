FROM ubuntu:14.04.5

RUN apt-get update && apt-get install -y \
    curl \
    gcc \
    graphviz \
    libdbd-mysql-perl \
    make \
    sqlite3 \
    ;

RUN curl --silent https://raw.githubusercontent.com/miyagawa/cpanminus/1.7039/cpanm | perl - App::cpanminus
RUN cpanm Carton@v1.0.22

ADD cpanfile /app/
ADD cpanfile.snapshot /app/

WORKDIR /app
RUN carton install --deployment

# TODO
RUN cpanm SQL::Easy

RUN mkdir /data_db/
RUN mkdir /data/

ADD app.psgi /app/
ADD cmd /app/

CMD ./cmd
