FROM google/dart:latest

RUN apt-get update && apt-get install -y -q libsqlite3-dev

# We ocassionally have to change this file to manually trigger rebuilds in the CI. Particularly, after a new Dart SDK
# version is out.