FROM google/dart:2.12-beta

RUN apt-get update && apt-get install -y --no-install-recommends apt-transport-https wget gnupg2 ca-certificates curl git libsqlite3-dev
