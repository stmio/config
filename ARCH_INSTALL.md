# Arch installation notes

## Reference materials

1. https://wiki.archlinux.org/title/Installation_guide
2. https://wiki.archlinux.org/title/Dm-crypt/Encrypting_an_entire_system#LUKS_on_a_partition_with_TPM2_and_Secure_Boot
3. https://wiki.archlinux.org/title/Unified_kernel_image#mkinitcpio
4. https://wiki.archlinux.org/title/Btrfs
5. https://wiki.archlinux.org/title/General_recommendations
6. https://walian.co.uk/arch-install-with-secure-boot-btrfs-tpm2-luks-encryption-unified-kernel-images.html

## Disk partitions

### Disk 1
- Partition 1: 4GiB (type "EFI System")
- Partition 2: Remaining space (type "Linux root (x86-64)")

### Disk 2
- Partition 1: Whole drive (type "Linux home")

## Useful commands

Set preferred font:

```
setfont ter-c20b
```

Create and mount LUKS volumes:

```
cryptsetup luksFormat -s 512 -h sha512 -i 5000 --sector-size 4096 /dev/nvme0n1p2
cryptsetup luksFormat -s 512 -h sha512 -i 5000 --sector-size 4096 /dev/nvme1n1p1

cryptsetup open /dev/nvme0n1p2 root
cryptsetup open /dev/nvme1n1p1 home
```

Create and mount btrfs filesystems on unlocked LUKS volumes:

```
mkfs.btrfs -s 4096 -L root /dev/mapper/root
mkfs.btrfs -s 4096 -L home /dev/mapper/home

mount -o compress=zstd /dev/mapper/root /mnt
mount -o compress=zstd /dev/mapper/home /mnt/home --mkdir
```

Setup EFI system partition:

```
mkfs.fat -F 32 /dev/nvme0n1p1
mount /dev/nvme0n1p1 /mnt/efi --mkdir
```

Select optimal mirrors:

```
reflector --country GB --age 24 --protocol http,https --sort rate --save /etc/pacman.d/mirrorlist
```

Install packages:

```
pacstrap -K /mnt base linux linux-firmware {amd/intel}-ucode btrfs-progs nano man-db man-pages texinfo base-devel cryptsetup dosfstools util-linux git unzip sbctl networkmanager zsh sudo
```

Change root to new system:

```
arch-chroot /mnt
```

Enable systemd units for network etc.:

```
systemctl enable systemd-resolved systemd-timesyncd NetworkManager
```

Modify hooks in `/etc/mkinitcpio.conf`, as follows:

```
HOOKS=(base systemd autodetect microcode modconf kms keyboard sd-vconsole block sd-encrypt filesystems fsck)
```

[Setup unified kernel images](https://wiki.archlinux.org/title/Unified_kernel_image#mkinitcpio)

Set root password, then reboot (and remove the installation medium):

```
passwd
exit
umount -R /mnt
reboot
```

Setup secure boot (set secure boot to setup mode):

```
sbctl create-keys
sbctl enroll-keys -m
sbctl verify
sbctl sign -s {file from last cmd}
sbctl status
```

Enroll the TPM:

```
# Root partition
systemd-cryptenroll /dev/nvme0n1p2 --recovery-key
systemd-cryptenroll /dev/nvme0n1p2 --wipe-slot=empty --tpm2-device=auto --tpm2-with-pin=yes --tpm2-pcrs=0+7

# Home partition
systemd-cryptenroll /dev/nvme1n1p1 --recovery-key
systemd-cryptenroll /dev/nvme1n1p1 --wipe-slot=empty --tpm2-device=auto --tpm2-with-pin=yes --tpm2-pcrs=0+7
```

> [!NOTE]  
> The home partition can also be unlocked automatically with a keyfile stored on the encrypted root partition.
> In this case, skip the last command in the block above and see [this wiki page](https://wiki.archlinux.org/title/Dm-crypt/System_configuration#Unlocking_with_a_keyfile).

Unlock and mount home partition on boot (not automounted by systemd as on different drive) with `fstab` and `crypttab`:

```
# /etc/crypttab
home UUID=<UUID of partition> none tpm2-device=auto

# /etc/fstab
/dev/mapper/home /home btrfs defaults,compress=zstd 0 0
```

Reboot, then setup personal user account:

```
useradd -m -G wheel -s /usr/bin/zsh sam
passwd sam
```

Configure permissions so that the wheel group can use [`sudo`](https://wiki.archlinux.org/title/Sudo#Example_entries) and [`su`](https://wiki.archlinux.org/title/Su#su_and_wheel) but only with a password. 
