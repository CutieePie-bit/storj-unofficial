# Unoffical Docker Image rebase of Storj.io Storagenode compiled binarys

In April 2022, the storagenode binary was removed from the storj.io docker container and replaced with an autoupdate process to pull the binary.

This causes issues for users wishing to target a specific release, as the docker container no longer related to the version of storagenode binary which had been historically the case.

All we do is revert the dockerimage to a state prior to April 2022, while still using the offical storj.io release binary, so that now docker image being built will be tagged with the corresponsing version of the binary used.

To build the image, as we are using multi-architecture, we need to have Qemu installed and enabled to facilitate building ARM images on X64 hardware.