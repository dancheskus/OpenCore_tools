#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
cd "$dir/OC_Switch_Files/"

if [[ ! $(mount | awk '$3 == "/Volumes/EFI" {print $3}') ]]; then
  echo "Mounting EFI Partition. Enter password if neaded."
  sudo diskutil mount EFI
fi

if [[ ! $(mount | awk '$3 == "/Volumes/EFI" {print $3}') ]]; then
  clear
  read -t 5 -p "Problems with mounting EFI Partition. Exiting..."
else
  clear

  nvramOCRecord="$(nvram 4D1FDA02-38C7-4A6A-9CC6-4BCCA8B30102:opencore-version | awk '{print $2}')"
  nvramOCMode="$(echo $nvramOCRecord | awk -F- '{print $1}')"
  nvramOCVer="$(echo $nvramOCRecord | awk -F- '{print $2}')"
  echo -e "\033[1mCurrent OpenCore version in NVRAM:"; tput sgr0
  if [[ $nvramOCMode == "DBG" ]]; then echo -e "   \033[1mMode: \033[2mDebug"; fi
  if [[ $nvramOCMode == "REL" ]]; then echo -e "   \033[1mMode: \033[2mRelease"; fi; tput sgr0
  echo -e "   \033[1mVersion: \033[2m$nvramOCVer"
  tput sgr0; echo

  echo -e "\033[1mFile versions in EFI partition:"; tput sgr0
  
  releaseBootFileNOTFound="$(diff RELEASE/BOOTx64.efi /Volumes/EFI/EFI/BOOT/BOOTx64.efi)"
  debugBootFileNOTFound="$(diff DEBUG/BOOTx64.efi /Volumes/EFI/EFI/BOOT/BOOTx64.efi)"
  if [[ $releaseBootFileNOTFound ]]; then echo -e "   \033[1mBOOTx64.efi: \033[2mDebug"; fi
  if [[ $debugBootFileNOTFound ]]; then echo -e "   \033[1mBOOTx64.efi: \033[2mRelease"; fi
  tput sgr0;

  releaseOpenCoreFileNOTFound="$(diff RELEASE/OpenCore.efi /Volumes/EFI/EFI/OC/OpenCore.efi)"
  debugOpenCoreFileNOTFound="$(diff DEBUG/OpenCore.efi /Volumes/EFI/EFI/OC/OpenCore.efi)"
  if [[ $releaseOpenCoreFileNOTFound ]]; then echo -e "   \033[1mOpenCore.efi: \033[2mDebug"; fi
  if [[ $debugOpenCoreFileNOTFound ]]; then echo -e "   \033[1mOpenCore.efi: \033[2mRelease"; fi
  tput sgr0;

  releaseBootstrapFileNOTFound="$(diff RELEASE/Bootstrap.efi /Volumes/EFI/EFI/OC/Bootstrap/Bootstrap.efi)"
  debugBootstrapFileNOTFound="$(diff DEBUG/Bootstrap.efi /Volumes/EFI/EFI/OC/Bootstrap/Bootstrap.efi)"
  if [[ $releaseBootstrapFileNOTFound ]]; then echo -e "   \033[1mBootstrap.efi: \033[2mDebug"; fi
  if [[ $debugBootstrapFileNOTFound ]]; then echo -e "   \033[1mBootstrap.efi: \033[2mRelease"; fi
  tput sgr0;

  releaseOpenRuntimeFileNOTFound="$(diff RELEASE/OpenRuntime.efi /Volumes/EFI/EFI/OC/Drivers/OpenRuntime.efi)"
  debugOpenRuntimeFileNOTFound="$(diff DEBUG/OpenRuntime.efi /Volumes/EFI/EFI/OC/Drivers/OpenRuntime.efi)"
  if [[ $releaseOpenRuntimeFileNOTFound ]]; then echo -e "   \033[1mOpenRuntime.efi: \033[2mDebug"; fi
  if [[ $debugOpenRuntimeFileNOTFound ]]; then echo -e "   \033[1mOpenRuntime.efi: \033[2mRelease"; fi


  # echo; echo; echo; echo; echo; echo "Replacing files..."
  # cp RELEASE/OpenCore.efi /Volumes/EFI/EFI/OC
  # cp RELEASE/Bootstrap.efi /Volumes/EFI/EFI/OC/Bootstrap
  # cp RELEASE/OpenRuntime.efi /Volumes/EFI/EFI/OC/Drivers
  # cp RELEASE/BOOTx64.efi /Volumes/EFI/EFI/BOOT

  # echo ""
  # echo "Changing config..."
  # plutil -replace "Misc.Debug.Target" -integer 3 /Volumes/EFI/EFI/OC/config.plist
  # echo ""
  # read -t 5 -p "Done. Exiting..."

  # echo; echo; echo; echo; echo; echo "Replacing files..."
  # cp DEBUG/OpenCore.efi /Volumes/EFI/EFI/OC
  # cp DEBUG/Bootstrap.efi /Volumes/EFI/EFI/OC/Bootstrap
  # cp DEBUG/OpenRuntime.efi /Volumes/EFI/EFI/OC/Drivers
  # cp DEBUG/BOOTx64.efi /Volumes/EFI/EFI/BOOT

  # echo ""
  # echo "Changing config..."
  # plutil -replace "Misc.Debug.Target" -integer 67 /Volumes/EFI/EFI/OC/config.plist
  # echo ""
  # read -t 5 -p "Done. Exiting..."

fi
