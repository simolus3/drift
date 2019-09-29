#!/usr/bin/env bash

cd moor
pub run build_runner test --delete-conflicting-outputs
pub run test_coverage --no-badge