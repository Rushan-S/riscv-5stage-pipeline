# RISC-V 5-Stage Pipelined Processor

A fully functional 5-stage pipelined RISC-V processor (RV32I) implemented in Verilog. Designed, debugged, and verified in ModelSim with a 10-instruction test program covering all major hazard scenarios.

---

## Pipeline Architecture

```
IF → ID → EX → MEM → WB
```

| Stage | Module | Description |
|-------|--------|-------------|
| IF | `stage_IF` | Fetches instruction from memory using PC |
| ID | `stage_ID` | Decodes instruction, reads registers, generates control signals |
| EX | `stage_EX` | Executes ALU operation, computes branch/jump target |
| MEM | `stage_MEM` | Reads/writes data memory |
| WB | `stage_WB` | Writes result back to register file |

Pipeline registers between stages: `reg_IF_ID`, `reg_ID_EX`, `reg_EX_MEM`, `reg_MEM_WB`

---

## Hazard Handling

### Data Hazards — Forwarding
The forwarding unit detects RAW hazards and forwards results directly to the ALU without stalling.

| Signal | Path | When it fires |
|--------|------|---------------|
| `forwardA` | EX/MEM → ALU port A | Instruction in EX needs result of instruction in MEM |
| `forwardA` | MEM/WB → ALU port A | Instruction in EX needs result of instruction in WB |
| `forwardB` | EX/MEM → ALU port B | Same as above for port B, only when ALU uses rs2 (not immediate) |
| `forwardS` | EX/MEM or MEM/WB → store data | SW needs forwarded rs2 value for store data independent of ALU |

`forwardB` is gated by `!idex_aluscr_mux` — it only fires when the instruction actually uses rs2 as an ALU input, preventing immediate instructions like `addi` from incorrectly receiving a forwarded value.

`forwardS` is a separate signal for the store data path — SW uses an immediate for the address calculation but still needs rs2 forwarded for the data being stored.

### Load-Use Hazard — Stall
When a `lw` is followed immediately by an instruction that uses the loaded value, the hazard detection unit (`hdu`) inserts a 1-cycle stall:
- PC is frozen
- IF/ID register is frozen
- ID/EX register is flushed (bubble inserted)

### Control Hazards — Branch Flushing
When a branch or jump is taken, `pc_selector != 00` triggers a flush of the IF/ID and ID/EX pipeline registers, discarding the two incorrectly fetched instructions.

---

## Supported Instructions

| Type | Instructions |
|------|-------------|
| R-type | `add` `sub` `and` `or` `xor` `sll` `srl` `sra` `slt` |
| I-type ALU | `addi` `andi` `ori` `xori` `slli` `srli` `srai` `slti` |
| I-type Load | `lw` |
| S-type | `sw` |
| B-type | `beq` `bne` `blt` `bge` |
| U-type | `lui` `auipc` |
| J-type | `jal` `jalr` |

---

## Simulation Results

Tested with ModelSim using a 10-instruction program that covers all hazard scenarios:

```
inst_mem[0]  = addi x1, x0, 5       // x1 = 5
inst_mem[1]  = addi x2, x0, 1       // x2 = 1
inst_mem[2]  = add  x3, x1, x2      // x3 = 6  — EX→EX forwarding
inst_mem[3]  = add  x3, x2, x3      // x3 = 7  — MEM→EX forwarding
inst_mem[4]  = sw   x3, 0(x2)       // mem[0] = 7
inst_mem[5]  = lw   x4, 0(x2)       // x4 = 7  — load-use stall
inst_mem[6]  = add  x5, x4, x4      // x5 = 14 — forwarding after load
inst_mem[7]  = bne  x3, x5, +4      // branch not taken (7 != 14)
inst_mem[8]  = addi x6, x0, 3       // x6 = 3
inst_mem[9]  = add  x7, x5, x6      // x7 = 17
```

| Instruction | Expected Result | Status |
|-------------|----------------|--------|
| `addi x1, x0, 5` | x1 = 5 | ✅ |
| `addi x2, x0, 1` | x2 = 1 | ✅ |
| `add x3, x1, x2` | x3 = 6 | ✅ EX→EX forwarding |
| `add x3, x2, x3` | x3 = 7 | ✅ MEM→EX forwarding |
| `sw x3, 0(x2)` | mem[0] = 7 | ✅ store verified |
| `lw x4, 0(x2)` | x4 = 7 | ✅ load-use stall |
| `add x5, x4, x4` | x5 = 14 | ✅ post-load forwarding |
| `bne x3, x5` | not taken | ✅ branch logic correct |
| `addi x6, x0, 3` | x6 = 3 | ✅ |
| `add x7, x5, x6` | x7 = 17 | ✅ |

---

## Files

| File | Description |
|------|-------------|
| `riscv-top.v` | Full processor source — all modules in one file |
| `tb_risc.v` | Testbench with 30-cycle simulation |
| `Wave.do` | ModelSim wave layout with labeled cursors |
| `Waveform.png` | Waveform screenshot showing all passing results |
| `Instructionwaveform.png` | Waveform screenshot with instruction labels |

---

## How to Simulate

**ModelSim:**
```tcl
vlog riscv-top.v tb_risc.v
vsim work.tb
do Wave.do
run 261ns
```

**Verify results:**
```tcl
examine -hex tb/dut/s_id/rf1/register(1)   // expect 00000005
examine -hex tb/dut/s_id/rf1/register(2)   // expect 00000001
examine -hex tb/dut/s_id/rf1/register(3)   // expect 00000007
examine -hex tb/dut/s_id/rf1/register(4)   // expect 00000007
examine -hex tb/dut/s_id/rf1/register(5)   // expect 0000000e
examine -hex tb/dut/s_id/rf1/register(6)   // expect 00000003
examine -hex tb/dut/s_id/rf1/register(7)   // expect 00000011
```

---

## Tools
- Intel quartus
- ModelSim Intel FPGA 
- Verilog HDL 
