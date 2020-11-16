#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
cd "$dir/OC_Switch_Files/"

if [[ $(mount | awk '$3 == "/Volumes/EFI" {print $3}') == "" ]]; then
  echo "Mounting EFI Partition. Enter password if neaded."
  sudo diskutil mount EFI
fi

if [[ $(mount | awk '$3 == "/Volumes/EFI" {print $3}') == "" ]]; then
  clear
  read -t 5 -p "Problems with mounting EFI Partition. Exiting..."
else

  nvramReleaseRecord="$(nvram 4D1FDA02-38C7-4A6A-9CC6-4BCCA8B30102:opencore-version | grep REL)"
  nvramDebugRecord="$(nvram 4D1FDA02-38C7-4A6A-9CC6-4BCCA8B30102:opencore-version | grep DBG)"

  clear
  if [[ $nvramReleaseRecord != "" ]]; then echo -e "\033[1mCurrent OpenCore version: \033[2mRelease"; fi
  if [[ $nvramDebugRecord != "" ]]; then echo -e "\033[1mCurrent OpenCore version: \033[2mDebug"; fi
  tput sgr0

  echo; echo; echo; echo; echo; echo "Replacing files..."
  cp DEBUG/OpenCore.efi /Volumes/EFI/EFI/OC
  cp DEBUG/Bootstrap.efi /Volumes/EFI/EFI/OC/Bootstrap
  cp DEBUG/OpenRuntime.efi /Volumes/EFI/EFI/OC/Drivers
  cp DEBUG/BOOTx64.efi /Volumes/EFI/EFI/BOOT

  echo ""
  echo "Changing config..."
  plutil -replace "Misc.Debug.Target" -integer 67 /Volumes/EFI/EFI/OC/config.plist
  echo ""
  read -t 5 -p "Done. Exiting..."

fi
