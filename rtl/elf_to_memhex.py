#!/usr/bin/env python3
# elf_to_memhex.py
# Produce imem.hex (word-per-line, little-endian) and dmem.hex (byte-per-line)
# from an ELF file. Requires pyelftools: pip install pyelftools

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
        # aggregate all LOAD segments
        imem_bytes = {}  # addr -> byte
        for seg in elf.iter_segments():
            if seg['p_type'] != 'PT_LOAD':
                continue
            vaddr = seg['p_vaddr']
            data = seg.data()
            for i, b in enumerate(data):
                imem_bytes[vaddr + i] = b

    # produce imem word lines starting at rom_origin up to highest address in text region
    # find max addr
    if not imem_bytes:
        print("No loadable segments found in ELF")
        sys.exit(1)
    min_addr = min(imem_bytes.keys())
    max_addr = max(imem_bytes.keys())
    print(f"ELF loadable min=0x{min_addr:x} max=0x{max_addr:x}")

    # imem: write words at addresses starting from rom_origin up to max_addr
    start = rom_origin
    end = max_addr
    # align start to word
    if start % 4 != 0:
        start = start - (start % 4)
    # also ensure end aligned up
    if (end % 4) != 0:
        end = end + (4 - (end % 4))

    with open(args.out_imem, "w") as imem_f:
        for addr in range(start, end+1, 4):
            # build little-endian word
            w = 0
            for i in range(4):
                byte = imem_bytes.get(addr + i, 0)
                w |= (byte << (8 * i))
            imem_f.write("{:08x}\n".format(w))

    # dmem: include only bytes whose address is in RAM region
    with open(args.out_dmem, "w") as dmem_f:
        # find min and max in ram region
        ram_addrs = [a for a in imem_bytes.keys() if a >= ram_origin]
        if ram_addrs:
            ram_min = min(ram_addrs)
            ram_max = max(ram_addrs)
            # write every byte from ram_origin up to ram_max
            for addr in range(ram_origin, ram_max+1):
                b = imem_bytes.get(addr, 0)
                dmem_f.write("{:02x}\n".format(b))
        else:
            # nothing to write; create empty dmem
            pass

    print(f"Wrote {args.out_imem} and {args.out_dmem}")

if __name__ == "__main__":
    main()
