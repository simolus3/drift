#!/usr/bin/env bash

dart moor/tool/format_coverage.dart --packages=moor/.packages

bash <(curl -s https://codecov.io/bash) -f lcov.info
