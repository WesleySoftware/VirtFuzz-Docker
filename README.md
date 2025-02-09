# VirtFuzz-Docker
Packaging VirtFuzz into a docker container for CYSE-610

## Usage
```
make
./run.sh
```

Then once you are in the container you can 

## Troubleshooting
### The fuzzer is crashing because the VM is timing out!
To troubleshoot this, try invoking the VM with QEMU directly without the fuzzer. The following command should boot the VM once you are in the container:
```sh
../qemu/build/qemu-system-x86_64 \
    -drive file=/fuzz/VirtFuzz/guestimage/bullseye.img,format=raw \
    -m 1024M \
    -display none \
    -serial stdio \
    -boot order=c \
    -net none \
    -append "root=/dev/sda console=ttyS0" \
    -kernel $KERNEL
```
If that does not work, troubleshoot your setup to ensure QEMU is able to boot the Syzkallered VM.

## FAQ
Q: Why are you running debootstrap outside the container?

A: When I tried running debootstrap in the docker build it couldn't mount the chroot as a loopback device because [docker can't build in a "privileged" way](https://github.com/moby/moby/issues/1916). You can get around this by using buildah to make the container image instead, but it was easier to just copy the syzkaller debian image into the container.
