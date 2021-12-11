#!/bin/bash

make build
make publish
make fmt-check
make plan
make apply
make pytest