[![Vulnerabilities](https://sonarcloud.io/api/project_badges/measure?project=CutieePie-bit_storj-unofficial&metric=vulnerabilities)](https://sonarcloud.io/summary/new_code?id=CutieePie-bit_storj-unofficial) [![Quality gate](https://sonarcloud.io/api/project_badges/quality_gate?project=CutieePie-bit_storj-unofficial)](https://sonarcloud.io/summary/new_code?id=CutieePie-bit_storj-unofficial)

# Unoffical Rebase of Storj Storagenode code

Repackage offical release binary into Alpine container, removing the dependancy on Storagenode-Updater which attempts to prevent pull requests from docker hub based on a released build.

to-do

#fix alpine images by building in nested QEMU instance<p>
#streamline dockerfiles<p>
#remove hard coded dependencys
