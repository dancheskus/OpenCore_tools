#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
cd "$dir"
firmwareType=""

EFIFolder="/Volumes/EFI/EFI"
configFilePath="$EFIFolder/OC/config.plist"
bootArgsPath="NVRAM.Add.7C436110-AB2A-4BBB-A880-FE41995C9F82.boot-args"
nvramOCRecord="$(nvram 4D1FDA02-38C7-4A6A-9CC6-4BCCA8B30102:opencore-version | awk '{print $2}')"
bootArgs=""
isVerbose=""
OCVer=""

checkEFIisMounted() {
  if [[ ! $(mount | awk '$3 == "/Volumes/EFI" {print $3}') ]]; then
    clear
    read -t 2 -p "EFI Volume was unmounted. Exiting..."
    break 2
  fi
}

getOCVer() {
  nvramOCVer="$(echo $nvramOCRecord | awk -F- '{print $2}')"
  OCVer=""
  for (( i = 0; i < ${#nvramOCVer}; ++i )); do
    # adding dots in OC version
    OCVer="$OCVer${nvramOCVer:$i:1}"
    [[ $(($i+1)) != ${#nvramOCVer} ]] && OCVer="$OCVer."
  done
}

mkcd () { mkdir "$1"; cd "$1"; }

downloadFiles() {
  rm -rf Files/$OCVer
  [ ! -d "Files" ] && mkcd "Files" || cd "Files"
  mkcd "$OCVer"

  download() {
    mkcd $1
    fileName="OpenCore-$OCVer-$1"
    echo "Downloading $firmwareType $(echo $1 | awk '{print tolower($0)}') files ($OCVer)..."
    curl -sOL https://github.com/acidanthera/OpenCorePkg/releases/download/$OCVer/$fileName.zip
    unzip -qq $fileName.zip
    rm $fileName.zip

    cd ..
  }

  download "DEBUG"
  download "RELEASE"
}

filterFiles() {
  firmwareTypeUpperCase=$(echo $firmwareType | awk '{print toupper($0)}')
  filter() {
    cd $1
    ls | grep -v $firmwareTypeUpperCase | xargs rm -rf
    mv $firmwareTypeUpperCase/EFi/* . 
    rm -rf $firmwareTypeUpperCase
    mv BOOT/* .
    rm -rf BOOT
    mv OC/Bootstrap/Bootstrap.efi .
    mv OC/OpenCore.efi .
    mv OC/Drivers/OpenRuntime.efi .
    rm -rf OC
    cd ..
  }
  
  filter "DEBUG"
  filter "RELEASE"
}

downloadFilesIfNeaded() {
  debugFilePath="Files/$OCVer/DEBUG"
  releaseFilePath="Files/$OCVer/RELEASE"
  
  if [[
      ! -f "$debugFilePath/Bootstrap.efi" ||
      ! -f "$debugFilePath/BOOT$firmwareType.efi" ||
      ! -f "$debugFilePath/OpenCore.efi" ||
      ! -f "$debugFilePath/OpenRuntime.efi" ||
      ! -f "$releaseFilePath/Bootstrap.efi" ||
      ! -f "$releaseFilePath/BOOT$firmwareType.efi" ||
      ! -f "$releaseFilePath/OpenCore.efi" ||
      ! -f "$releaseFilePath/OpenRuntime.efi"  ]]; then
    downloadFiles
    filterFiles
  fi

  cd $dir
}

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

switchOCMode() {
  # if $1 != DEBUG function will work as "RELEASE"
  cp Files/$OCVer/$1/OpenCore.efi $EFIFolder/OC
  cp Files/$OCVer/$1/Bootstrap.efi $EFIFolder/OC/Bootstrap
  cp Files/$OCVer/$1/OpenRuntime.efi $EFIFolder/OC/Drivers
  cp Files/$OCVer/$1/BOOT$firmwareType.efi $EFIFolder/BOOT

  [[ $1 == "DEBUG" ]] && replaceDebugTarget 67 || replaceDebugTarget 3
  [[ $1 == "DEBUG" ]] && setVerbose "enable" || setVerbose "disable"
}

printHeader() { printf "\033[44m$1\n"; tput sgr0; }
printTitle() { printf "\033[1m$1\n"; tput sgr0; }
printKey() { printf "   \033[1m$1: "; }
printValue() { printf "\033[2m$1\n"; tput sgr0; }

printInfo() {
  clear

  printHeader " This app helps toggling between OpenCore RELEASE and DEBUG modes "; echo

  
  nvramOCMode="$(echo $nvramOCRecord | awk -F- '{print $1}')"

  nvramText="(Data from NVRAM. Is updating after reboot)"

  printTitle "Info:"
  printKey "Mode"
  if [[ $nvramOCMode == "DBG" ]]; then printValue "Debug $nvramText"; fi
  if [[ $nvramOCMode == "REL" ]]; then printValue "Release $nvramText"; fi
  
  printKey "Version"; printValue "$OCVer $nvramText"
  
  printKey "Firmware type"; printValue $firmwareType
  
  printKey "Verbose mode enabled"
  if [[ $isVerbose ]]; then printValue "True"; fi
  if [[ ! $isVerbose ]]; then printValue "False"; fi

  echo

  printTitle "File versions in EFI partition:"

  printFileMode() {
    # $1: File name; $2: File path in EFI Volume
    releaseFileNOTFound="$(diff Files/$OCVer/RELEASE/$1 $EFIFolder/$2/$1)"
    debugFileNOTFound="$(diff Files/$OCVer/DEBUG/$1 $EFIFolder/$2/$1)"
    printKey $1
    if [[ $releaseFileNOTFound ]]; then printValue "Debug"; fi
    if [[ $debugFileNOTFound ]]; then printValue "Release"; fi
  }

  printFileMode "BOOT$firmwareType.efi" "BOOT"
  printFileMode "OpenCore.efi" "OC"
  printFileMode "Bootstrap.efi" "OC/Bootstrap"
  printFileMode "OpenRuntime.efi" "OC/Drivers"
  
  echo; echo; echo; echo; echo;
}

if [[ ! $(mount | awk '$3 == "/Volumes/EFI" {print $3}') ]]; then
  clear
  printHeader " Mounting EFI Partition. Enter password if neaded. "; echo

  sudo diskutil mount EFI
fi

if [[ ! $(mount | awk '$3 == "/Volumes/EFI" {print $3}') ]]; then
  clear
  read -t 2 -p "Problems with mounting EFI Partition. Exiting..."
else
  getOCVer
  firmwareType=$(ls /Volumes/EFI/EFI/BOOT | grep BOOT | awk -F "[T.]" '{print $2}')
  downloadFilesIfNeaded

  while true; do
    updateIsVerbose
    printInfo

    options=("Switch to OpenCore Release" "Switch to OpenCore Debug" "Toggle verbose mode (-v)" "Quit")

    printHeader " Choose an option: "; echo
    COLUMNS=0
    select opt in "${options[@]}"; do
      case $REPLY in
        1) checkEFIisMounted; switchOCMode "RELEASE"; break ;;
        2) checkEFIisMounted; switchOCMode "DEBUG"; break ;;
        3) checkEFIisMounted; [[ $isVerbose ]] && setVerbose "disable" || setVerbose "enable"; break ;;
        4) break 2 ;;
        *) echo "What's that?" >&2 ;;
      esac
    done
  done

  echo "Bye bye!"

fi
