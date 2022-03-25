# Unoffical Rebase of Storj Storagenode code

Repackage offical release binary into Alpine container, removing the dependancy on Storagenode-Updater which attempts to prevent pull requests from docker hub based on a released build.

to-Do

#fix alpine images by building in nested QEMU instance
#streamline dockerfiles
#remove hard coded dependencys
