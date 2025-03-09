#!/bin/bash
#genisoimage -e boot/grub/efi.img -no-emul-boot -R -J -T -c boot.catalog -hide boot.catalog -V "GXDE" -o gxde.iso loong64/
#genisoimage -r -loliet-long -V GXDE -o gxde.iso -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -R -J -v -cache-inodes -T -eltorito-alt-boot -b boot/grub/efi.img -no-emul-boot ISO-temp/
xorriso -as mkisofs -R -r -J -joliet-long -l -cache-inodes -iso-level 3 -A "GXDE"  -V "GXDE"  -partition_offset 16 -append_partition '2' '0xef' loong64/boot/grub/efi.img -appended_part_as_gpt  -eltorito-catalog boot.catalog -eltorito-alt-boot -e --interval:appended_partition_2:all:: -e boot/grub/efi.img -no-emul-boot -isohybrid-gpt-basdat -isohybrid-apm-hfsplus -o gxde.iso loong64
