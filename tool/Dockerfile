FROM ubuntu:rolling

RUN apt-get update && apt-get install -y --no-install-recommends apt-transport-https wget gnupg2 ca-certificates curl git

# Setup for Dart
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -
RUN wget -qO- https://storage.googleapis.com/download.dartlang.org/linux/debian/dart_stable.list > /etc/apt/sources.list.d/dart_stable.list
ENV PATH="/usr/lib/dart/bin:${PATH}"

# Setup for Google Chrome
RUN echo 'deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main' | tee /etc/apt/sources.list.d/google-chrome.list

#RUN apt-get update && apt-get install -y --no-install-recommends -q libsqlite3-dev google-chrome-stable firefox dart
RUN apt-get update && apt-get install -y --no-install-recommends -q libsqlite3-dev dart

# We ocassionally have to change this file to manually trigger rebuilds in the CI. Particularly, after a new Dart SDK
# version is out. Prefer to use Dart 2.9 or above.