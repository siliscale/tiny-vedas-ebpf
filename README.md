# Tiny Vedas - eBPF SoC

A complete, fully tested System-on-Chip (SoC) implementation with a CPU that executes the eBPF (extended Berkeley Packet Filter) instruction set architecture. The SoC includes a pipelined eBPF processor, instruction memory, and data memory, all written in SystemVerilog with comprehensive verification.

## Features

### Architecture
- **ISA**: eBPF (extended Berkeley Packet Filter) v1.0
- **Pipeline**: 4-stage pipeline (IFU → IDU0 → IDU1 → EXU)
- **Data Width**: 64-bit registers (11 registers: R0-R10)
- **Memory**: Harvard architecture with separate instruction and data memories
- **Reset Vector**: Configurable

### Instruction Set Support
- **Arithmetic**: ADD, SUB, MUL, DIV, MOD (64-bit and 32-bit variants)
- **Logical**: AND, OR, XOR
- **Shifts**: LSH (left shift), RSH (right shift), ARSH (arithmetic right shift)
- **Comparison**: JEQ, JGT, JGE, JLT, JLE, JNE, JSGT, JSGE, JSLT, JSLE, JSET
- **Jumps**: JMP, JMP32 (conditional branches)
- **Memory**: Load/Store operations (8, 16, 32, 64-bit)
  - LD/LDX: Load from memory
  - ST/STX: Store to memory
  - LD64: Load 64-bit immediate (wide instruction)
- **Special**: MOV, EXIT, CALL, Endianness conversion

### Advanced Features
- **Data Hazard Resolution**: Register forwarding from EXU to IDU1
- **Control Hazard Handling**: Pipeline flush on branches
- **Multi-cycle Operations**: Pipelined multiplier and divider
- **Unaligned Memory Access**: Support for byte and half-word aligned loads/stores
- **Memory Forwarding**: Store-to-load forwarding for performance

## Project Structure

```
tiny-vedas-ebpf/
├── rtl/                    # RTL design files
│   ├── core_top.sv        # Top-level SoC module
│   ├── core_top.flist     # File list for synthesis
│   ├── ifu/               # Instruction fetch unit
│   │   └── ifu.sv         # IFU implementation
│   ├── idu/               # Instruction decode units
│   │   ├── idu0.sv        # Decode stage 0
│   │   ├── idu1.sv        # Decode stage 1
│   │   ├── reg_file.sv    # Register file (11 eBPF registers)
│   │   ├── ebpf_decoder.sv # Auto-generated eBPF decode logic
│   │   └── decode         # Decode table specification
│   ├── exu/               # Execute unit
│   │   ├── exu.sv         # Execute unit top-level
│   │   ├── alu.sv         # Arithmetic logic unit
│   │   ├── mul.sv         # Multiplier unit
│   │   ├── div.sv         # Divider unit
│   │   └── lsu.sv         # Load/store unit
│   ├── include/           # Global definitions
│   │   ├── global.svh     # Global parameters
│   │   └── types.svh      # Type definitions
│   └── lib/               # Utility modules
│       ├── mem_lib.sv     # Memory modules
│       └── beh_lib.sv     # Behavioral models
├── ebpf-iss/              # eBPF Instruction Set Simulator
│   └── main.py            # ISS for generating execution traces
├── tests/                 # Test programs
│   ├── asm/              # Assembly test programs
│   ├── c/                # C program tests
│   └── raw/              # Raw binary tests
├── dv/                    # Design verification
│   ├── sv/               # SystemVerilog testbenches
│   │   ├── core_top_tb.sv # Main testbench
│   │   └── lsu_tb.sv      # LSU testbench
│   └── verilator/        # Verilator simulation files
├── tools/                 # Development utilities
│   ├── dec_table_gen.py  # Decode table generator
│   └── sim_manager.py    # Simulation manager
├── open-decode-tables/    # Decode table specifications
│   └── tables/           # eBPF instruction decode tables
├── work/                  # Simulation output directory
├── SVLib/                 # SystemVerilog library
├── Makefile              # Build and simulation targets
└── LICENSE               # Apache 2.0 license
```

## Quick Start

### Prerequisites
- **SystemVerilog Simulator**: Verilator (recommended) or Xilinx Vivado
- **eBPF Toolchain**: LLVM/Clang with eBPF target support
- **Python 3**: For build scripts and ISS
- **Ubuntu 20.04+**: Tested platform

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/siliscale/Tiny-Vedas-eBPF.git
   cd Tiny-Vedas-eBPF
   ```

2. **Install dependencies**
   ```bash
   # Install Verilator
   sudo apt-get install verilator
   
   # Install LLVM/Clang with eBPF support
   sudo apt-get install clang llvm
   
   # Install Python dependencies
   pip install -r requirements.txt
   ```

3. **Build and run simulation**
   ```bash
   # Run core simulation
   make core_top_sim
   
   # Run specific tests
   cd tests/asm
   make basic_add_i
   ```

## Simulation

### Core Simulation
```bash
make core_top_sim
```
This runs the main testbench with Verilator, executing eBPF test programs and generating execution traces. The simulation compares RTL execution traces with the eBPF ISS (Instruction Set Simulator) for verification.

### Individual Unit Tests
```bash
# Test load/store unit
make lsu_sim

# Test specific eBPF assembly programs
cd tests/asm
make basic_add_i    # Test ALU immediate operations
make basic_mul      # Test multiplication
make basic_branch   # Test branch instructions
```

### C Program Tests
```bash
cd tests/c
make helloworld     # Compile C to eBPF and run
```

### Using the eBPF ISS
The eBPF Instruction Set Simulator (`ebpf-iss/main.py`) can be used independently to generate reference traces:
```bash
python3 ebpf-iss/main.py test_program.o -o iss.log
```

## Configuration

### Memory Configuration
- **Instruction Memory**: Separate instruction memory for eBPF program code
- **Data Memory**: Separate data memory for stack and data operations
- **Stack Pointer (R10)**: Configurable initial value (register R10 is read-only frame pointer)

### Pipeline Configuration
- **Stages**: 4-stage pipeline
- **Forwarding**: Full forwarding from EXU to IDU1
- **Stalling**: Multi-cycle operation support

## Verification

### Test Coverage
- **Unit Tests**: Individual component verification
- **Integration Tests**: Full pipeline verification
- **Instruction Tests**: Complete eBPF instruction set coverage
- **Hazard Tests**: Data and control hazard scenarios
- **ISS Comparison**: RTL traces compared against eBPF ISS reference traces

### Test Results
Simulation results are logged to:
- `rtl.log`: RTL instruction execution trace
- `iss.log`: ISS reference execution trace
- `sim.log`: Simulation comparison results
- Waveform files: For detailed timing analysis

## Synthesis

### FPGA Synthesis
```bash
# Generate decode tables
make decodes

# Synthesize with Vivado
make vivado_synth
```

### ASIC Synthesis
The design is synthesizable with standard ASIC tools. Use `rtl/core_top.flist` as the file list.

## Performance

### Pipeline Performance
- **CPI**: ~1.0 for most workloads
- **Branch Penalty**: 1 cycle for taken branches
- **Memory Latency**: 1 cycle for aligned accesses

### Resource Utilization
- **Registers**: ~2000 flip-flops (11 eBPF registers × 64 bits)
- **LUTs**: ~5000 (FPGA estimate)
- **Memory**: Separate instruction and data memories

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

### Development Guidelines
- Follow SystemVerilog coding standards
- Add comprehensive tests for new features
- Update documentation for API changes
- Ensure all tests pass before submitting

## License

This project is licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE) for details.

## Acknowledgments

- Linux kernel eBPF project for the eBPF instruction set architecture
- Verilator team for the fast SystemVerilog simulator
- LLVM project for eBPF toolchain support
- Open-source community for tools and libraries

## Support

For issues and questions:
- Open a GitHub issue
- Check the test programs for usage examples
- Review the SystemVerilog source code for implementation details
