docker run --rm -it --name tmp -w /root/workspace/ -v ~/Documents/dev/operation-systems/nanobyte-os/:/root/workspace/ os-compilation-img make floppy_image
make qemu_run