#!/bin/bash
set -eu


#be sure to run it passing-through kvm
docker run --privileged --device=/dev/kvm -it $(docker build -q .) /bin/bash

