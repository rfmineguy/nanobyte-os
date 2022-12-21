docker run --rm -it --name tmp -w /root/workspace/ -v ~/Documents/dev/operation-systems/nanobyte-os/:/root/workspace/ rfmineguy/os-comp-image make floppy_image
make qemu_run