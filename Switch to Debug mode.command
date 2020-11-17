#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
cd "$dir/OC_Switch_Files/"

EFIFolder="/Volumes/EFI/EFI"
configFilePath="$EFIFolder/OC/config.plist"
bootArgsPath="NVRAM.Add.7C436110-AB2A-4BBB-A880-FE41995C9F82.boot-args"
bootArgs=""
isVerbose=""

function setVerbose() {
  bootArgsWithoutVebose="$(echo $bootArgs | awk -F"-v" '{print $1,$2}' | awk -v OFS=' ' '{$1=$1}1')"

  if [[ $1 == "enable" && ! $isVerbose ]]; then plutil -replace $bootArgsPath -string "$bootArgsWithoutVebose -v" $configFilePath; fi
  if [[ $1 == "disable" && $isVerbose ]]; then plutil -replace $bootArgsPath -string "$bootArgsWithoutVebose" $configFilePath; fi
}

function switchToOCRelease() {
  # echo
  # echo
  # echo
  # echo
  # echo
  # echo "Replacing files..."
  cp RELEASE/OpenCore.efi $EFIFolder/OC
  cp RELEASE/Bootstrap.efi $EFIFolder/OC/Bootstrap
  cp RELEASE/OpenRuntime.efi $EFIFolder/OC/Drivers
  cp RELEASE/BOOTx64.efi $EFIFolder/BOOT

  # echo ""
  # echo "Changing config..."
  plutil -replace "Misc.Debug.Target" -integer 3 $configFilePath
  setVerbose "disable"
  # echo ""
  # read -t 5 -p "Done. Exiting..."
}

function switchToOCDebug() {
  # echo
  # echo
  # echo
  # echo
  # echo
  # echo "Replacing files..."
  cp DEBUG/OpenCore.efi $EFIFolder/OC
  cp DEBUG/Bootstrap.efi $EFIFolder/OC/Bootstrap
  cp DEBUG/OpenRuntime.efi $EFIFolder/OC/Drivers
  cp DEBUG/BOOTx64.efi $EFIFolder/BOOT

  # echo ""
  # echo "Changing config..."
  plutil -replace "Misc.Debug.Target" -integer 67 $configFilePath
  setVerbose "enable"
  # echo ""
  # read -t 5 -p "Done. Exiting..."
}

function printInfo() {
  clear

  nvramOCRecord="$(nvram 4D1FDA02-38C7-4A6A-9CC6-4BCCA8B30102:opencore-version | awk '{print $2}')"
  nvramOCMode="$(echo $nvramOCRecord | awk -F- '{print $1}')"
  nvramOCVer="$(echo $nvramOCRecord | awk -F- '{print $2}')"
  echo -e "\033[1mCurrent OpenCore version in NVRAM:"
  tput sgr0
  if [[ $nvramOCMode == "DBG" ]]; then echo -e "   \033[1mMode: \033[2mDebug (Is updating after reboot)"; fi
  if [[ $nvramOCMode == "REL" ]]; then echo -e "   \033[1mMode: \033[2mRelease (Is updating after reboot)"; fi
  tput sgr0
  echo -e "   \033[1mVersion: \033[2m$nvramOCVer"
  tput sgr0
  if [[ $isVerbose ]]; then echo -e "   \033[1mVerbose mode enabled: \033[2mTrue"; fi
  if [[ ! $isVerbose ]]; then echo -e "   \033[1mVerbose mode enabled: \033[2mFalse"; fi
  tput sgr0
  echo

  echo -e "\033[1mFile versions in EFI partition:"
  tput sgr0

  releaseBootFileNOTFound="$(diff RELEASE/BOOTx64.efi $EFIFolder/BOOT/BOOTx64.efi)"
  debugBootFileNOTFound="$(diff DEBUG/BOOTx64.efi $EFIFolder/BOOT/BOOTx64.efi)"
  if [[ $releaseBootFileNOTFound ]]; then echo -e "   \033[1mBOOTx64.efi: \033[2mDebug"; fi
  if [[ $debugBootFileNOTFound ]]; then echo -e "   \033[1mBOOTx64.efi: \033[2mRelease"; fi
  tput sgr0

  releaseOpenCoreFileNOTFound="$(diff RELEASE/OpenCore.efi $EFIFolder/OC/OpenCore.efi)"
  debugOpenCoreFileNOTFound="$(diff DEBUG/OpenCore.efi $EFIFolder/OC/OpenCore.efi)"
  if [[ $releaseOpenCoreFileNOTFound ]]; then echo -e "   \033[1mOpenCore.efi: \033[2mDebug"; fi
  if [[ $debugOpenCoreFileNOTFound ]]; then echo -e "   \033[1mOpenCore.efi: \033[2mRelease"; fi
  tput sgr0

  releaseBootstrapFileNOTFound="$(diff RELEASE/Bootstrap.efi $EFIFolder/OC/Bootstrap/Bootstrap.efi)"
  debugBootstrapFileNOTFound="$(diff DEBUG/Bootstrap.efi $EFIFolder/OC/Bootstrap/Bootstrap.efi)"
  if [[ $releaseBootstrapFileNOTFound ]]; then echo -e "   \033[1mBootstrap.efi: \033[2mDebug"; fi
  if [[ $debugBootstrapFileNOTFound ]]; then echo -e "   \033[1mBootstrap.efi: \033[2mRelease"; fi
  tput sgr0

  releaseOpenRuntimeFileNOTFound="$(diff RELEASE/OpenRuntime.efi $EFIFolder/OC/Drivers/OpenRuntime.efi)"
  debugOpenRuntimeFileNOTFound="$(diff DEBUG/OpenRuntime.efi $EFIFolder/OC/Drivers/OpenRuntime.efi)"
  if [[ $releaseOpenRuntimeFileNOTFound ]]; then echo -e "   \033[1mOpenRuntime.efi: \033[2mDebug"; fi
  if [[ $debugOpenRuntimeFileNOTFound ]]; then echo -e "   \033[1mOpenRuntime.efi: \033[2mRelease"; fi

  tput sgr0
  echo
  echo
  echo
  echo
  echo
}

if [[ ! $(mount | awk '$3 == "/Volumes/EFI" {print $3}') ]]; then
  echo "Mounting EFI Partition. Enter password if neaded."
  sudo diskutil mount EFI
fi

if [[ ! $(mount | awk '$3 == "/Volumes/EFI" {print $3}') ]]; then
  clear
  read -t 5 -p "Problems with mounting EFI Partition. Exiting..."
else

  while true; do
    bootArgs="$(plutil -extract $bootArgsPath xml1 -o - $configFilePath | grep string | awk -F "[><]" '{print $3}')"
    isVerbose="$(echo $bootArgs | awk '/-v/ {print}')"
    printInfo

    options=("Switch to OpenCore Release" "Switch to OpenCore Debug" "Toggle verbose mode" "Quit")

    echo "Choose an option: "
    select opt in "${options[@]}"; do
      case $REPLY in
      1)
        switchToOCRelease
        break
        ;;
      2)
        switchToOCDebug
        break
        ;;
      3)
        if [[ $isVerbose ]]; then setVerbose "disable"; fi
        if [[ ! $isVerbose ]]; then setVerbose "enable"; fi
        break
        ;;
      4) break 2 ;;
      *) echo "What's that?" >&2 ;;
      esac
    done
  done

  echo "Bye bye!"

fi
