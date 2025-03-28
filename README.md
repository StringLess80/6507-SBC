# 6507 SBC
SBC realizzato con il processore 6507 (famiglia del 6502)

![6502sbc(6507rev2) - Copy](https://github.com/user-attachments/assets/d3e65ab7-2f9a-4ca4-8bb0-4d3a2f0a1303)

2 KiB RAM
2 KiB ROM
interfaccia seriale
1x 6522 VIA

hexdump -e '"1%03_ax: " 16/1 "%02X " "\n"' <PROGRAMMA>.bin | awk '{print toupper($0)}'
