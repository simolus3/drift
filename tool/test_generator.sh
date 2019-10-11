#!/usr/bin/env bash

cd moor_generator

# todo figure out why analyzer tests don't run on the CI (it throws an internal error)
pub run test --exclude-tags analyzer