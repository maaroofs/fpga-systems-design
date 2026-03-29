# fpga-systems-design

A collection of digital systems projects implemented on the **Zynq-7000 SoC** (Zybo Z7 / Blackboard FPGA), spanning RTL design in Verilog, ARM assembly programming, and bare-metal C applications. Each module is self-contained with source files, simulation testbenches, and XDC pin constraints.

---

## Tools & Hardware

| Tool | Version |
|------|---------|
| Xilinx Vivado | 2023.1 |
| Xilinx Vitis | 2023.1 |
| Target Board | Zybo Z7-20 / Blackboard (Zynq-7000 SoC) |
| HDL Language | Verilog |
| Software Language | C, ARM Assembly (Cortex-A9) |

---

## Repository Structure

```
fpga-systems-design/
├── 01_programmable_counter/     # 4-bit counter with 100MHz→1Hz clock divider
│   ├── counter.v
│   ├── clock_divider.v
│   ├── top_counter.v
│   ├── counter_constraints.xdc
│   └── sim/
│       └── tb_counter.v
│
├── 02_serial_adder_fsm/         # 4-state Moore FSM serial adder
│   ├── serial_adder_fsm.v
│   ├── edge_detect.v
│   ├── top_serial_adder.v
│   ├── fsm_constraints.xdc
│   └── sim/
│       └── tb_serial_adder_fsm.v
│
├── 03_zynq_gpio_assembly/       # Zynq PS: C + ARM assembly array sum, GPIO LEDs
│   └── src/
│       ├── main.c
│       └── sum_array.s
│
└── 04_axi_timer_uart/           # AXI Timer interrupt + UART-controlled LED patterns
    └── src/
        └── main.c
```

---

## Modules

### 01 — Programmable Counter

A synchronous 4-bit up-counter with active-high reset and a clock enable input. A prescaler clock divider brings the 100 MHz board clock down to approximately 1 Hz, making the count visible on LEDs without additional hardware.

**Features**
- Synchronous reset, clock-enable gating
- Carry-out signal pulses for one cycle on rollover (15 → 0)
- Modular design: divider and counter are instantiated separately in a top-level wrapper
- Full simulation testbench covering reset, enable, and rollover

**IO Mapping**

| Signal | Board Pin |
|--------|-----------|
| `clk` | H16 (100 MHz oscillator) |
| `rst_btn` | BTN0 |
| `leds[3:0]` | LED0–LED3 |
| `carry_led` | LED4 |

---

### 02 — Serial Adder FSM

A 4-state Moore finite state machine implementing a 1-bit serial adder. The FSM processes one pair of input bits per clock cycle and correctly tracks the carry from one bit position to the next across state transitions.

**State Diagram**

```
       rst
        |
        v
   +----S0----+   A&B -> S2
   |  F=0     |
   | Cout=0   |<-------------------------------+
   +----------+                                |
       |  A^B                                  |
       v                                       |
   +---S1---+  A&B -> S2                       |
   |  F=1   |----+    ~A&~B -> S0              |
   | Cout=0 |<---+                             |
   +--------+                                  |
                                               |
   +---S2---+  A&B -> S3    ~A&~B -> S1        |
   |  F=0   |----+-----------------------------+
   | Cout=1 |<---+
   +--------+

   +---S3---+  A&B -> S3    others -> S1/S2
   |  F=1   |
   | Cout=1 |
   +--------+
```

**Features**
- Step-by-step FPGA testing via button-controlled clock enable
- Rising-edge detector for clean single-cycle step pulses (metastability safe)
- Comprehensive simulation testbench covering all state transitions

**IO Mapping**

| Signal | Board Pin |
|--------|-----------|
| `clk` | H16 |
| `rst_btn` | BTN0 — reset FSM to S0 |
| `step_btn` | BTN1 — advance FSM one step |
| `sw[0]` | SW0 — serial input A |
| `sw[1]` | SW1 — serial input B |
| `led[0]` | LED0 — sum output F |
| `led[1]` | LED1 — carry output Cout |

---

### 03 — Zynq SoC GPIO + ARM Assembly

A bare-metal Vitis application running on the Zynq-7000 ARM Cortex-A9 processing system. Demonstrates mixed-language development by calling an ARM assembly function from C, and controls on-board LEDs through an AXI GPIO peripheral.

**Features**
- ARM assembly function (`sum_array`) accumulates a 32-bit integer array using the AAPCS calling convention (arguments in R0–R3)
- C application reads DIP switches via AXI GPIO and mirrors their state to LEDs in a polling loop
- Result of assembly computation printed over UART at 115200 baud

**Assembly Function Signature**
```c
// Prototype declared in C, implemented in sum_array.s
int sum_array(int *arr, int size);
```

**Setup**
1. Open Vivado, create a block design with the Zynq7 Processing System IP and two AXI GPIO blocks (one for LEDs, one for switches)
2. Run Block Automation and Connection Automation
3. Generate bitstream and export hardware (`.xsa`)
4. Open Vitis, create a new application project from the `.xsa`
5. Add `main.c` and `sum_array.s` to the `src/` folder
6. Build and run on hardware

---

### 04 — AXI Timer + UART LED Control

A bare-metal Vitis application using the AXI Timer peripheral and the Zynq interrupt controller (GIC) to generate an accurate interrupt-driven 3-second delay. Simultaneously receives single-character commands over UART to control LED patterns.

**Timer Configuration**
- AXI clock: 50 MHz
- Reload value calculated for 3-second period: `0xFFFFFFFF - (50,000,000 × 3) + 1`
- Auto-reload mode — timer restarts automatically on overflow

**UART Commands (115200 baud)**

| Character | Action |
|-----------|--------|
| `1` | Turn all LEDs ON |
| `0` | Turn all LEDs OFF |
| `A` | Turn on LED3 and LED1 only |
| `B` | Blink all LEDs 5× with 1-second interval |

**Features**
- Interrupt-driven timer — LED toggling does not block the main loop
- Main loop prints a free-running uptime counter every second using `sleep()`
- UART polling interleaved with counter print for non-blocking character handling

**Setup**
1. In Vivado, add Zynq PS, AXI Timer, and AXI GPIO to the block design
2. Enable `IRQ_F2P` in the Zynq PS interrupt settings and connect the AXI Timer interrupt pin
3. Set AXI Timer width to 32-bit, enable Timer 2
4. Set GPIO address range to 4 KB in the address editor
5. Generate bitstream, export `.xsa`, create Vitis project
6. Add `main.c` to `src/`, build, and deploy

---

## Running Simulations

Each RTL module includes a Verilog testbench. To run in Vivado:

1. Add the design source (`.v`) and the simulation source (`sim/tb_*.v`) to a Vivado project
2. In the Flow Navigator, click **Run Simulation → Run Behavioral Simulation**
3. Use **Zoom Fit** in the waveform viewer to see the full timing diagram

Alternatively, simulate with open-source tools:

```bash
# Install Icarus Verilog
sudo apt install iverilog gtkwave

# Example: simulate the counter
cd 01_programmable_counter
iverilog -o sim.out counter.v clock_divider.v sim/tb_counter.v
vvp sim.out
gtkwave tb_counter.vcd
```

---

## Key Concepts Demonstrated

- **Synchronous RTL design** — clocked always blocks, registered outputs, reset strategies
- **Clock domain management** — prescaler-based clock division, clock-enable gating
- **Finite state machines** — Moore FSM with explicit next-state and output logic separation
- **Metastability mitigation** — two-flop synchronizer for button input debouncing
- **Zynq PS/PL integration** — AXI4-Lite GPIO, AXI Timer, interrupt controller (GIC)
- **Mixed-language development** — ARM Cortex-A9 assembly called from bare-metal C (AAPCS)
- **UART communication** — polled receive loop, character-driven LED control

---

## License

MIT License — see [LICENSE](LICENSE) for details.
