 5-Stage Pipelined RISC-V Processor (RV32I)

A fully functional, from-scratch implementation of a pipelined RISC-V processor synthesized on FPGA hardware.**

![RISC-V Processor Running on Arty S7](docs/hardware_demo.jpg)
*Binary counter running in real-time on the Arty S7 FPGA - every LED state represents actual processor execution!*

Note: Full demo videos showing the processor in action are available in the `demos/` folder. They were too large to embed here, but showcase the binary counter and LED patterns running on real hardware.

---

## Project Highlights

This is a **complete, working RISC-V RV32I processor** that I designed and implemented from the ground up. What makes this special:

- **Actually works on real hardware** - not just simulation!
- **5-stage pipeline** with hazard detection and data forwarding
- **Memory-mapped I/O** - direct hardware control through software
- **Zero compromises** - proper handling of all hazards and edge cases (Well, almost; feed forwarding hazards are not supported)
- **Synthesizable** - runs at 100MHz on Xilinx FPGA hardware

## Demo Videos

Check out the `demos/` folder a videos showing the processor in action. There are three videos each displaying the binary up-counter I built. 


## Architecture Overview

### Pipeline Stages

```
┌────────┐    ┌────────┐    ┌────────┐    ┌────────┐    ┌────────┐
│   IF   │───▶│   ID   │───▶│   EX   │───▶│  MEM   │───▶│   WB   │
│ Fetch  │    │ Decode │    │Execute │    │ Memory │    │  Write │
└────────┘    └────────┘    └────────┘    └────────┘    └────────┘
     ▲                                           │
     │                                           │
     └───────────── Branch Resolution ───────────┘
```
While the above is an accurate description of the pipeline, it is also relevant to know that there exists a control unit—an essential component for the CPU's function.

### Key Features

**Pipeline Control:**
- Hazard detection unit prevents RAW hazards
- Data forwarding paths (EX→EX, MEM→EX)
- Pipeline flushing for branch mispredictions
- Proper stall insertion for load-use hazards

**Instruction Support (RV32I Base):**
- R-type: ADD, SUB, AND, OR, XOR, SLT, SLTU, SLL, SRL, SRA
- I-type: ADDI, ANDI, ORI, XORI, SLTI, SLTIU, SLLI, SRLI, SRAI
- Load/Store: LW, LH, LB, LHU, LBU, SW, SH, SB
- Branches: BEQ, BNE, BLT, BGE, BLTU, BGEU
- Jumps: JAL, JALR
- Upper Immediate: LUI, AUIPC

For those who are looking to develop a CPU on their own I have some comments for you. Adding more instructions is monotonous and banal. An invarient to each of the instructions is essentially bit shifting, decoder managment, generating the proper control signals, and a little more. The best instructions which taught me the most would without a doubt be AUIPC, but also jumps. AUIPC is essential for PIC which will teach you a lot since you should meet PIC criteria. Overall it is simple, but this is a part of the process where you get to do designing and make your own choices. For example, I have a subtractor that uses the base of say IMEM and PC to compute where you are and where the effective address (or offset) "really takes us." This is specific to my implementation as IMEM is not the base of my entire memory—well that is not fully correct. I have had many linker scirpts with quite a few different implementations, the subtractor makes all of them work.


**Memory System:**
- Block RAM for instruction memory (4K words)
- Block RAM for data memory (16KB)
- Memory-mapped GPIO (0x8000_0000)
- Proper byte/halfword/word access with sign extension

## Project Structure

```
risc-v-processor/
├── rtl/                    # Hardware description (SystemVerilog)
│   ├── Fetch/             # IF stage: PC, instruction memory
│   ├── Decode/            # ID stage: register file, control unit
│   ├── EX/                # EX stage: ALU, forwarding, hazard detection
│   ├── MEM/               # MEM stage: data memory, GPIO
│   ├── cpu_top.sv         # Top-level processor integration
│   └── arty_s7_top.sv     # FPGA board wrapper
├── constraints/           # Pin assignments for Arty S7
├── software/              # RISC-V assembly programs
│   ├── lightshow.s       # Binary counter demo
│   ├── verify_bram.s     # Hardware test
│   └── Makefile          # Build system (RISC-V toolchain)
├── demos/                # Video demonstrations
└── docs/                 # Documentation
```

## Problems for those who use my repo to learn:

### The Challenge: Real Hazards, Real Solutions

Building a pipelined processor isn't just about connecting stages - it's about handling the fundamental challenges that arise when multiple instructions execute simultaneously:

**1. Data Hazards (Solved!)**
```
ADDI t0, zero, 16    # t0 = 16
ADDI t1, t0, 20      # Needs t0 immediately! (RAW hazard)
```
My solution: Dual-path forwarding network that detects dependencies and routes fresh data directly from EX and MEM stages.

**2. Load-Use Hazards (Solved!)**
```
LW   t0, 0(a0)       # Load from memory (takes 1 cycle)
ADDI t1, t0, 5       # Can't forward yet - data not ready!
```
My solution: Intelligent hazard detection unit that stalls the pipeline for exactly one cycle when needed.

**3. Control Hazards (Solved!)**
```
BEQ  t0, t1, target  # Branch decision happens in EX stage
ADDI t2, t2, 1       # Already fetched - might be wrong!
```
My solution: Pipeline flush mechanism that squashes incorrect instructions and redirects fetch immediately. You need a control unit.

### Design Decisions That Matter

**Why 5 stages and not more?**
The classic 5-stage pipeline (IF-ID-EX-MEM-WB) provides the best balance for RV32I:
- Simple enough to achieve high clock frequencies
- Deep enough to improve instruction throughput
- Each stage has roughly equal work (critical path balancing)

Look into decoupled pipelines! 

**Memory-Mapped I/O:**
Rather than complex peripheral interfaces, I mapped the GPIO to address 0x8000_0000. This means:
```
*(volatile uint32_t*)0x80000000 = 0x55;  // Just write to turn on LEDs!
```
The processor doesn't know it's controlling LEDs - it's just storing to memory. The magic happens when the memory subsystem routes this address to GPIO registers instead of RAM.

## Testing & Verification

### Hardware Validation

**Test 1: Zero Register Enforcement**
```assembly
li   a1, 0          # Write to x0 (should be ignored)
```
Result: x0 always reads as zero, even after attempted writes

**Test 2: Hazard Handling**
```assembly
lui  a0, 0x80000    # Load upper immediate
addi a1, a0, 16     # Immediate use - tests forwarding
```
Result: No stalls needed - forwarding delivers the data

**Test 3: Load-Use Stall**
```assembly
lw   t0, 0(a0)      # Load from memory
add  t1, t0, t2     # Immediate use
```
Result: Automatic 1-cycle stall inserted

### The Binary Counter Demo

The lightshow program demonstrates:
1. **AUIPC/LUI** - Loading 32-bit immediates properly
2. **Memory operations** - Store to GPIO address
3. **Arithmetic** - Counter increment logic
4. **Branches** - Delay loop with proper branch prediction
5. **Pipeline efficiency** - Sustained 1 IPC (instructions per cycle) for straight-line code

## What I Learned

I knew nothing about CPUs when I started. I have never written a line of asssembly, tcl, makefile, C, and even SystemVerilog before getting started. I did not know what Vivado was or anything about FPGAs. I did not know what RISC-V was nor did I know of differing architecture types (whether it be  a memory layout or pipeline) and I didn't even know what an ISA was! 

Though, I learnt quickly, reading tons and tons of articlees, and even written about 50 pages of my own documenation—which if you are an employer with my resume you can find that on my Notion. It is very hard to demostrate this, but if I where to pin point a few things that matter the most but aren't emphasised ever when looking things up like "how to make a RISC_V CPU," below are 5 points which are relevant:

1. **Clock domain challenges** - Synchronizing FPGA clock with CPU execution 
-(though this wasn't much, a WNS of -0.743 )
2. **Critical path optimization** - Every gate delay matters at 100MHz
3. **Block RAM constraints** - FPGA memory has specific timing requirements
4. **Hardware debugging techniques** - Logic analyzers and systematic verification
5. **The beauty of ISA design** - RISC-V's orthogonality makes implementation elegant—also having a plan was about 90% of the work! Low level stuff is simple and can be coded within a few hours at worst, but bad design choices can take weeks to resolve...sadly...


## Building & Running

### Prerequisites (AKA what I used)
- Xilinx Vivado 2025.2 (or compatible)
- Arty S7-25 or S7-50 FPGA board
- RISC-V GNU toolchain (for software compilation)

If you are on mac and in a university, AWS provides 100 free credits: downlaod Vivado there and run things there. While I have never used AWS before this, it is not too hard to launch and instance.
Also, testing may be hard. Icarus Verilog works and GTKWave gave me tons of issues. I found that the fastest approach was asm test and tracing PC through the entire pipeline as if you are the PC. Again, a good design will leave you with very few errors, a bad one will leave you with a pile of work that is impossible to surmount.
### Synthesis & Programming

```
# 1. Open Vivado project
vivado risc_v_processor.xpr

# 2. Generate bitstream
# (Run Synthesis → Implementation → Generate Bitstream)

# 3. Program the FPGA
# Hardware Manager → Program Device
```

### Compiling Software

```
cd software/
make all        # Builds all demos
make coe        # Generates COE file for Block RAM initialization
```

### Loading New Programs

1. Generate COE file from your assembly program
2. Update Block RAM initialization in Vivado
3. Re-synthesize (or use updatemem for faster updates)
4. Program the FPGA

## Resource Utilization

On Xilinx Artix-7 (XC7S25):
- **LUTs:** ~2,100 (typical)
- **Flip-Flops:** ~1,400
- **Block RAM:** 4 tiles (32Kb instruction + data)
- **Clock:** 100 MHz

The design is **lightweight and efficient** - leaving plenty of resources for extensions!

## Future Enhancements

Potential areas for expansion:
- M extension (multiply/divide)
- Interrupt handling (machine mode)
- Cache system (I-cache + D-cache)
- Branch predictor (2-bit saturating counter)
- UART interface for program loading
- Performance counters
- Better hazard logic
- and so much more! No really...
## Documentation

Extensive inline comments throughout the codebase explain a few things but mainly:
- Design decisions and trade-offs
- Why certain approaches were chosen
- How each module interfaces with others
- Timing considerations for FPGA synthesis

See `rtl/Fetch/pc_mux.sv` for an example of detailed educational commenting about memory addressing. Please note that if you are an employer, on my Notion, there is a file you can find that is call ISA notes. Those are less so notes and more so my internal monologue while solving problems. I move all my note taking there after a while since it was more appropriate.

## Why This Project Matters

In an era where most computing happens in abstracted layers, building a processor from scratch provides direct insight into the fundamental mechanics of computation. Every instruction that executes on this processor is a direct result of deliberate design decisions - from branch prediction strategies to memory addressing schemes.

Additionally, even though the RISC-V vol 2 documentation provides a spectacular ISA it says nothing about implementing it-which you can use yourself!



**Interested in discussing computer architecture, FPGA design, or the hardware-software interface?**  
**I'm happy to dive into the technical details of this implementation. Reach out to me, beisenbe@uwaterloo.ca**

---

*Built with ❤️, SystemVerilog, and vehement passion*