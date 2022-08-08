FROM dart

RUN apt update
RUN DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt install -y chromium build-essential gcc
RUN ln -s /usr/bin/chromium /usr/bin/google-chrome
RUN chmod +x /usr/bin/google-chrome

RUN useradd -ms /bin/bash developer
RUN mkdir -p /app

USER developer
WORKDIR /home/developer

RUN cd /tmp/ &&\
  mkdir sqlite &&\
  cd sqlite &&\
  curl https://sqlite.org/2022/sqlite-autoconf-3380000.tar.gz --output sqlite.tar.gz &&\
  tar zxvf sqlite.tar.gz &&\
  cd sqlite-autoconf-3380000 &&\
  ./configure &&\
  make &&\
  mkdir ../out &&\
  cp sqlite3 ../out &&\
  cp .libs/libsqlite3.so ../out

USER developer
COPY --chown=developer:developer . /app/
WORKDIR /app/tool
RUN ./upgrade_all.sh

CMD export LD_LIBRARY_PATH=/tmp/sqlite/out ; ./test_all.sh
#; (cd .. && ./tool/misc_integration_test.sh)