#!/bin/bash
virsh --connect qemu:///system shutdown  "haos" --mode acpi || true
sudo scripts/enter.sh make O=output_ova ova
virsh --connect qemu:///system start "haos"