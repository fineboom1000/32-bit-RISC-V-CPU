#!/usr/bin/env python3
import sys, argparse
from elftools.elf.elffile import ELFFile

def main():
    p = argparse.ArgumentParser(description="ELF -> imem.hex (words) and dmem.hex (bytes)")
    p.add_argument("elf", help="input ELF")
    p.add_argument("--rom-origin", default="0x00001000", help="ROM VMA base (hex)")
    p.add_argument("--ram-origin", default="0x20000000", help="RAM VMA base (hex)")
    p.add_argument("--out-imem", default="imem.hex", help="output imem hex (word-per-line)")
    p.add_argument("--out-dmem", default="dmem.hex", help="output dmem hex (byte-per-line)")
    args = p.parse_args()

    rom_origin = int(args.rom_origin, 0)
    ram_origin = int(args.ram_origin, 0)

    with open(args.elf, "rb") as f:
        elf = ELFFile(f)
        all_bytes = {}
        for seg in elf.iter_segments():
            if seg['p_type'] != 'PT_LOAD':
                continue
            vaddr = seg['p_vaddr']
            data = seg.data()
            for i, b in enumerate(data):
                all_bytes[vaddr + i] = b

    if not all_bytes:
        print("No loadable segments found in ELF")
        sys.exit(1)

    min_addr = min(all_bytes.keys())
    max_addr = max(all_bytes.keys())
    print(f"ELF loadable min=0x{min_addr:x} max=0x{max_addr:x}")

    rom_bytes = {addr: all_bytes[addr] for addr in all_bytes if addr < ram_origin}
    ram_bytes = {addr: all_bytes[addr] for addr in all_bytes if addr >= ram_origin}

    if rom_bytes:
        rom_min = min(rom_bytes.keys())
        rom_max = max(rom_bytes.keys())
        start = rom_min & ~3
        end = (rom_max + 3) & ~3
        
        with open(args.out_imem, "w") as imem_f:
            for addr in range(start, end, 4):
                w = 0
                for i in range(4):
                    byte = rom_bytes.get(addr + i, 0)
                    w |= (byte << (8 * i))
                imem_f.write(f"{w:08x}\n")
        
        print(f"Wrote {(end - start) // 4} words to {args.out_imem}")
    else:
        open(args.out_imem, "w").close()

    if ram_bytes:
        ram_min = min(ram_bytes.keys())
        ram_max = max(ram_bytes.keys())
        
        with open(args.out_dmem, "w") as dmem_f:
            for addr in range(ram_min, ram_max + 1):
                b = ram_bytes.get(addr, 0)
                dmem_f.write(f"{b:02x}\n")
        
        print(f"Wrote {ram_max - ram_min + 1} bytes to {args.out_dmem}")
    else:
        open(args.out_dmem, "w").close()

if __name__ == "__main__":
    main()