# VirtFuzz-Docker
Packaging VirtFuzz into a docker container for CYSE-610

## Usage
```
make
./run.sh
```

Then once you are in the container you can execute the last two lines of the code block at https://github.com/WesleySoftware/VirtFuzz/blob/main/README.md#fuzzer (without sudo of course)
```sh
mkdir -p /dev/shm/virtfuzz-cache
./target/release/virtfuzz-fuzz --cache /dev/shm/virtfuzz-cache --device-definition device-definitions/hwsim-scan.json --stages standard --cores 1
```

Feel free to remove the `--cores` flag to let the fuzzer just eat your entire CPU

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

Often if the fuzzer crashes it doesn't clean up qemu processes, so you can run `pkill -9 qemu-syst` to free them up.

I have also had the experience where it will work without KVM using the following modified command
```sh
./target/release/virtfuzz-fuzz \
    --cache /dev/shm/virtfuzz-cache \
    --device-definition device-definitions/hwsim-scan.json \
    --stages standard \
    --cores 1 \
    --use-hwsim-input \
    --enable-qemu-logging \
    --single-thread \
    --disable-kvm \
    --timeout 1000ms
```

## FAQ
Q: Why are you running debootstrap outside the container?

A: When I tried running debootstrap in the docker build it couldn't mount the chroot as a loopback device because [docker can't build in a "privileged" way](https://github.com/moby/moby/issues/1916). You can get around this by using buildah to make the container image instead, but it was easier to just copy the syzkaller debian image into the container.
