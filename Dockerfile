FROM gmeligio/flutter-android:3.44.1

USER root

RUN apt update && apt install -y haproxy

# default name is google-chrome, so we link it
RUN ln -s /usr/bin/chromium /usr/bin/google-chrome

USER flutter
ENV PATH $HOME/.pub-cache/bin:$PATH

RUN dart pub global activate melos
RUN whoami

COPY --chown=flutter:flutter . /app/
WORKDIR /app
RUN dart pub get && melos bootstrap
RUN ./tool/upgrade_all.sh

ENTRYPOINT ["/app/tool/docker/entrypoint.sh"]

CMD export LD_LIBRARY_PATH=/tmp/sqlite/out ; ./tool/test_all.sh
#; (cd .. && ./tool/misc_integration_test.sh)
