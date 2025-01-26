# VirtFuzz-Docker
Packaging VirtFuzz into a docker container for CYSE-610

## Usage
```
make
./run.sh
```

## FAQ
Q: Why are you running debootstrap outside the container

A: When I tried running debootstrap in the docker build it couldn't mount the chroot as a loopback device because docker can't build in a "privileged" way. You can get around this by using buildah to make the container image instead, but it was easier to just copy the syzkaller debian image into the container.
