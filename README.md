# Alpine Openstack Virtual Machine

This project helps creating an [Alpine] based Openstack image.
It uses The [alpine-make-vm-image] script to build a disk image in QCOW2 format.

This image can then be uploaded to an openstack project with the following
command:

```console
> openstack --os-cloud mycloud image create --disk-format qcow2 --file alpine-openstack.qcow2 alpine-openstack
```

And a corresponding server can be created with:

```console
openstack --os-cloud mycloud server create --key-name mykey --image alpine-openstack --flavor myflavor alpine
```

The [terraform](./terraform) directory contains a sample terraform module using
the image to spawn a VM and create a DNS entry for it. It targets the french
Openstack cloud provider [OVHcloud].

## Hyper-V image

Along with each qcow2 image in each release there is also a vhdx version of the
image that can be started with Hyper-V on Windows. Its name is
`alpine-openstack.vhdx`.

To be able to run it on Windows without a metadata service, a small
[NoCloud](https://cloudinit.readthedocs.io/en/18.4/topics/datasources/nocloud.html) ISO
image `seed.iso` is provided. It allows connecting to the VM through SSH with
the password `passw0rd` (username `alpine`).

You can create the VM with:

```powershell
PS>  New-VM -Name debug -MemoryStartupBytes 2GB -Path . -BootDevice VHD -VHDPath .\alpine-openstack.vhdx -SwitchName "Default Switch" -Generation 1
PS> Set-VMDvdDrive -VMName debug -Path .\seed.iso
PS> Start-VM debug
PS> Get-NetNeighbor -LinkLayerAddress 00-15-5d-*

ifIndex IPAddress             LinkLayerAddress      State       PolicyStore
------- ---------             ----------------      -----       -----------
60      172.26.131.90         00-15-5D-25-01-8D     Reachable   ActiveStore
29      172.20.64.204         00-15-5D-00-3F-28     Permanent   ActiveStore

PS> ssh alpine@172.20.64.204
alpine@172.20.64.204 password:
Welcome to Alpine!

The Alpine Wiki contains a large amount of how-to guides and general
information about administrating Alpine systems.
See <https://wiki.alpinelinux.org/>.

You can setup the system with the command: setup-alpine

You may change this message by editing /etc/motd.

➜  ~ exit
PS>
```

More information on [this blog post](https://mrtn.me/posts/2023/01/13/debugging-a-failing-openstack-image/).

<!-- MARKDOWN LINKS & IMAGES -->

[alpine]: https://alpinelinux.org/
[alpine-make-vm-image]: https://github.com/alpinelinux/alpine-make-vm-image
[ovhcloud]: https://www.ovhcloud.com/fr/
