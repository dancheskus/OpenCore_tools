# #!/bin/bash

# dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
# cd "$dir/OC_Switch_Files/"

# EFIFolder="/Volumes/EFI/EFI"
# configFilePath="$EFIFolder/OC/config.plist"
# bootArgsPath="NVRAM.Add.7C436110-AB2A-4BBB-A880-FE41995C9F82.boot-args"
# bootArgs=""
# isVerbose=""

# replacePlist() { plutil -replace $1 $2 "$3" "$configFilePath"; }
# replaceBootArgs() { replacePlist "NVRAM.Add.7C436110-AB2A-4BBB-A880-FE41995C9F82.boot-args" "-string" "$1"; }
# replaceDebugTarget() { replacePlist "Misc.Debug.Target" "-integer" $1; }

# updateIsVerbose() {
#   bootArgs="$(plutil -extract $bootArgsPath xml1 -o - $configFilePath | grep string | awk -F "[><]" '{print $3}')"
#   isVerbose="$(echo $bootArgs | awk '/-v/ {print}')"
# }

# setVerbose() {
#   bootArgsWithoutVebose="$(echo $bootArgs | awk -F"-v" '{print $1,$2}' | awk -v OFS=' ' '{$1=$1}1')"
#   bootArgsWithVebose="$bootArgsWithoutVebose -v"

#   updateIsVerbose

#   if [[ $1 == "enable" && ! $isVerbose ]]; then replaceBootArgs "$bootArgsWithVebose"; fi
#   if [[ $1 == "disable" && $isVerbose ]]; then replaceBootArgs "$bootArgsWithoutVebose"; fi
# }

# switchOCMode() {
#   # if $1 != DEBUG function will work as "RELEASE"
#   cp $1/OpenCore.efi $EFIFolder/OC
#   cp $1/Bootstrap.efi $EFIFolder/OC/Bootstrap
#   cp $1/OpenRuntime.efi $EFIFolder/OC/Drivers
#   cp $1/BOOTx64.efi $EFIFolder/BOOT

#   [[ $1 == "DEBUG" ]] && replaceDebugTarget 67 || replaceDebugTarget 3
#   [[ $1 == "DEBUG" ]] && setVerbose "enable" || setVerbose "disable"
# }

# printHeader() { printf "\033[44m$1\n"; tput sgr0; }
# printTitle() { printf "\033[1m$1\n"; tput sgr0; }
# printKey() { printf "   \033[1m$1: "; }
# printValue() { printf "\033[2m$1\n"; tput sgr0; }

# printInfo() {
#   clear

#   printHeader "This app is working only with OC version 0.6.3 (x64)"; echo

#   nvramOCRecord="$(nvram 4D1FDA02-38C7-4A6A-9CC6-4BCCA8B30102:opencore-version | awk '{print $2}')"
#   nvramOCMode="$(echo $nvramOCRecord | awk -F- '{print $1}')"
#   nvramOCVer="$(echo $nvramOCRecord | awk -F- '{print $2}')"
#   nvramOCVerWithDots=""
#   for (( i = 0; i < ${#nvramOCVer}; ++i )); do
#     # adding dots in OC version
#     nvramOCVerWithDots="$nvramOCVerWithDots${nvramOCVer:$i:1}"
#     [[ $(($i+1)) != ${#nvramOCVer} ]] && nvramOCVerWithDots="$nvramOCVerWithDots."
#   done

#   printTitle "Current OpenCore version in NVRAM:"
#   printKey "Mode"
#   if [[ $nvramOCMode == "DBG" ]]; then printValue "Debug (Is updating after reboot)"; fi
#   if [[ $nvramOCMode == "REL" ]]; then printValue "Release (Is updating after reboot)"; fi
  
#   printKey "Version"; printValue $nvramOCVerWithDots
  
#   echo

#   printTitle "Config values:"
#   printKey "Verbose mode enabled"
#   if [[ $isVerbose ]]; then printValue "True"; fi
#   if [[ ! $isVerbose ]]; then printValue "False"; fi

#   echo

#   printTitle "File versions in EFI partition:"

#   printFileVersion() {
#     # $1: File name; $2: File path in EFI Volume
    
#     releaseFileNOTFound="$(diff RELEASE/$1 $EFIFolder/$2/$1)"
#     debugFileNOTFound="$(diff DEBUG/$1 $EFIFolder/$2/$1)"
#     printKey $1
#     if [[ $releaseFileNOTFound ]]; then printValue "Debug"; fi
#     if [[ $debugFileNOTFound ]]; then printValue "Release"; fi
#   }

#   printFileVersion "BOOTx64.efi" "BOOT"
#   printFileVersion "OpenCore.efi" "OC"
#   printFileVersion "Bootstrap.efi" "OC/Bootstrap"
#   printFileVersion "OpenRuntime.efi" "OC/Drivers"
  
#   echo; echo; echo; echo; echo;
# }

# if [[ ! $(mount | awk '$3 == "/Volumes/EFI" {print $3}') ]]; then
#   clear
#   printHeader "Mounting EFI Partition. Enter password if neaded."; echo

#   sudo diskutil mount EFI
# fi

# if [[ ! $(mount | awk '$3 == "/Volumes/EFI" {print $3}') ]]; then
#   clear
#   read -t 2 -p "Problems with mounting EFI Partition. Exiting..."
# else

#   while true; do
#     updateIsVerbose
#     printInfo

#     options=("Switch to OpenCore Release" "Switch to OpenCore Debug" "Toggle verbose mode (-v)" "Quit")

#     printHeader "Choose an option:"; echo
#     COLUMNS=0
#     select opt in "${options[@]}"; do
#       case $REPLY in
#         1) switchOCMode "RELEASE"; break ;;
#         2) switchOCMode "DEBUG"; break ;;
#         3) [[ $isVerbose ]] && setVerbose "disable" || setVerbose "enable"; break ;;
#         4) break 2 ;;
#         *) echo "What's that?" >&2 ;;
#       esac
#     done
#   done

#   echo "Bye bye!"

# fi

mkcd () { mkdir "$1"; cd "$1"; }

OCVer="0.6.2"
firmwareType="X64"

downloadFiles() {
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
  filter() {
    cd $1
    ls | grep -v $firmwareType | xargs rm -rf
    mv $firmwareType/EFi/* . 
    rm -rf $firmwareType
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


debugFilePath="Files/$OCVer/DEBUG"
releaseFilePath="Files/$OCVer/RELEASE"
if [[ ! -f "$debugFilePath/Bootstrap.efi" || ! -f "$debugFilePath/BOOT$firmwareType.efi" || ! -f "$debugFilePath/OpenCore.efi" || ! -f "$debugFilePath/OpenRuntime.efi" || ! -f "$releaseFilePath/Bootstrap.efi" || ! -f "$releaseFilePath/BOOT$firmwareType.efi" || ! -f "$releaseFilePath/OpenCore.efi" || ! -f "$releaseFilePath/OpenRuntime.efi"  ]]; then
  rm -rf Files/$OCVer
  downloadFiles
  filterFiles
fi