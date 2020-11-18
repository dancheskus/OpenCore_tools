#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
cd "$dir/OC_Switch_Files/"

EFIFolder="/Volumes/EFI/EFI"
configFilePath="$EFIFolder/OC/config.plist"
bootArgsPath="NVRAM.Add.7C436110-AB2A-4BBB-A880-FE41995C9F82.boot-args"
bootArgs=""
isVerbose=""

replacePlist() { plutil -replace $1 $2 "$3" "$configFilePath"; }
replaceBootArgs() { replacePlist "NVRAM.Add.7C436110-AB2A-4BBB-A880-FE41995C9F82.boot-args" "-string" "$1"; }
replaceDebugTarget() { replacePlist "Misc.Debug.Target" "-integer" $1; }

updateIsVerbose() {
  bootArgs="$(plutil -extract $bootArgsPath xml1 -o - $configFilePath | grep string | awk -F "[><]" '{print $3}')"
  isVerbose="$(echo $bootArgs | awk '/-v/ {print}')"
}

setVerbose() {
  bootArgsWithoutVebose="$(echo $bootArgs | awk -F"-v" '{print $1,$2}' | awk -v OFS=' ' '{$1=$1}1')"
  bootArgsWithVebose="$bootArgsWithoutVebose -v"

  updateIsVerbose

  if [[ $1 == "enable" && ! $isVerbose ]]; then replaceBootArgs "$bootArgsWithVebose"; fi
  if [[ $1 == "disable" && $isVerbose ]]; then replaceBootArgs "$bootArgsWithoutVebose"; fi
}

switchToOCRelease() {
  cp RELEASE/OpenCore.efi $EFIFolder/OC
  cp RELEASE/Bootstrap.efi $EFIFolder/OC/Bootstrap
  cp RELEASE/OpenRuntime.efi $EFIFolder/OC/Drivers
  cp RELEASE/BOOTx64.efi $EFIFolder/BOOT

  replaceDebugTarget 3
  setVerbose "disable"
}

switchToOCDebug() {
  cp DEBUG/OpenCore.efi $EFIFolder/OC
  cp DEBUG/Bootstrap.efi $EFIFolder/OC/Bootstrap
  cp DEBUG/OpenRuntime.efi $EFIFolder/OC/Drivers
  cp DEBUG/BOOTx64.efi $EFIFolder/BOOT

  replaceDebugTarget 67
  setVerbose "enable"
}

printHeader() { printf "\033[44m$1\n"; tput sgr0; }
printTitle() { printf "\033[1m$1\n"; tput sgr0; }
printKey() { printf "   \033[1m$1: "; }
printValue() { printf "\033[2m$1\n"; tput sgr0; }

printInfo() {
  clear

  printHeader "This app is working only with OC version 0.6.3 (x64)"; echo

  nvramOCRecord="$(nvram 4D1FDA02-38C7-4A6A-9CC6-4BCCA8B30102:opencore-version | awk '{print $2}')"
  nvramOCMode="$(echo $nvramOCRecord | awk -F- '{print $1}')"
  nvramOCVer="$(echo $nvramOCRecord | awk -F- '{print $2}')"

  printTitle "Current OpenCore version in NVRAM:"
  printKey "Mode"
  if [[ $nvramOCMode == "DBG" ]]; then printValue "Debug (Is updating after reboot)"; fi
  if [[ $nvramOCMode == "REL" ]]; then printValue "Release (Is updating after reboot)"; fi
  
  printKey "Version"; printValue $nvramOCVer
  
  echo

  printTitle "Config values:"
  printKey "Verbose mode enabled"
  if [[ $isVerbose ]]; then printValue "True"; fi
  if [[ ! $isVerbose ]]; then printValue "False"; fi

  echo

  printTitle "File versions in EFI partition:"


  releaseBootFileNOTFound="$(diff RELEASE/BOOTx64.efi $EFIFolder/BOOT/BOOTx64.efi)"
  debugBootFileNOTFound="$(diff DEBUG/BOOTx64.efi $EFIFolder/BOOT/BOOTx64.efi)"
  printKey "BOOTx64.efi"
  if [[ $releaseBootFileNOTFound ]]; then printValue "Debug"; fi
  if [[ $debugBootFileNOTFound ]]; then printValue "Release"; fi
  

  releaseOpenCoreFileNOTFound="$(diff RELEASE/OpenCore.efi $EFIFolder/OC/OpenCore.efi)"
  debugOpenCoreFileNOTFound="$(diff DEBUG/OpenCore.efi $EFIFolder/OC/OpenCore.efi)"
  printKey "OpenCore.efi"
  if [[ $releaseOpenCoreFileNOTFound ]]; then printValue "Debug"; fi
  if [[ $debugOpenCoreFileNOTFound ]]; then printValue "Release"; fi
  

  releaseBootstrapFileNOTFound="$(diff RELEASE/Bootstrap.efi $EFIFolder/OC/Bootstrap/Bootstrap.efi)"
  debugBootstrapFileNOTFound="$(diff DEBUG/Bootstrap.efi $EFIFolder/OC/Bootstrap/Bootstrap.efi)"
  printKey "Bootstrap.efi"
  if [[ $releaseBootstrapFileNOTFound ]]; then printValue "Debug"; fi
  if [[ $debugBootstrapFileNOTFound ]]; then printValue "Release"; fi
  

  releaseOpenRuntimeFileNOTFound="$(diff RELEASE/OpenRuntime.efi $EFIFolder/OC/Drivers/OpenRuntime.efi)"
  debugOpenRuntimeFileNOTFound="$(diff DEBUG/OpenRuntime.efi $EFIFolder/OC/Drivers/OpenRuntime.efi)"
  printKey "OpenRuntime.efi"
  if [[ $releaseOpenRuntimeFileNOTFound ]]; then printValue "Debug"; fi
  if [[ $debugOpenRuntimeFileNOTFound ]]; then printValue "Release"; fi
  
  echo; echo; echo; echo; echo;
}

if [[ ! $(mount | awk '$3 == "/Volumes/EFI" {print $3}') ]]; then
  clear
  printHeader "Mounting EFI Partition. Enter password if neaded."; echo

  sudo diskutil mount EFI
fi

if [[ ! $(mount | awk '$3 == "/Volumes/EFI" {print $3}') ]]; then
  clear
  read -t 2 -p "Problems with mounting EFI Partition. Exiting..."
else

  while true; do
    updateIsVerbose
    printInfo

    options=("Switch to OpenCore Release" "Switch to OpenCore Debug" "Toggle verbose mode (-v)" "Quit")

    printHeader "Choose an option:"; echo
    COLUMNS=0
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