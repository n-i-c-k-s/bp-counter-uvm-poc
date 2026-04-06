# bp_counter_uvm_poc

**Proof-of-concept UVM testbench for an 8-bit counter, running on both VCS and Verilator.**

Built as part of a GSoC proposal for *BlackParrot UVM Testbenches in Verilator*. Demonstrates the same UVM test running on an industry-standard simulator (VCS) and an open-source simulator (Verilator), with documented gaps and workarounds.

---

## DUT

`rtl/counter.sv` — 8-bit up-counter:
- `clk`, `rst_n` (active-low), `enable` → `count[7:0]`
- Increments on posedge clk when enable=1; resets to 0 when rst_n=0

## UVM Testbench Structure

```
tb/
  counter_if.sv                # Interface with clocking blocks (VCS)
  counter_if_verilator.sv      # Interface without clocking blocks (Verilator)
  counter_pkg.sv               # UVM package for VCS
  counter_pkg_verilator.sv     # UVM package for Verilator
  counter_seq_item.sv          # Sequence item (shared)
  counter_driver.sv            # Driver using clocking blocks (VCS)
  counter_driver_verilator.sv  # Driver using @(posedge clk) (Verilator)
  counter_monitor.sv           # Monitor with covergroup (VCS)
  counter_monitor_verilator.sv # Monitor without covergroup (Verilator)
  counter_agent.sv             # Agent: driver + monitor + sequencer (shared)
  counter_sequence.sv          # enable→disable→re-enable sequence (shared)
  counter_env.sv               # Environment (shared)
  counter_test.sv              # Test class (shared)
  tb_top.sv                    # Top-level for VCS
  tb_top_verilator.sv          # Top-level for Verilator
```

---

## TRACK A — VCS (Industry Standard)

### Prerequisites
- VCS U-2023.03-1 at `/eda/synopsys/vcs/U-2023.03-1`
- No additional installs needed (UVM ships with VCS)

### One-command build + run
```bash
make -f Makefile.vcs
```

### Expected output
```
UVM_INFO @ 0:        [RNTST] Running test counter_test...
UVM_INFO @ 0:        [TEST]  === counter_test: run_phase starting ===
UVM_INFO @ 0:        [SEQ]   Starting counter_sequence
UVM_INFO @ 35000:    [DRV]   Driving: enable=1 num_cycles=8
UVM_INFO @ 115000:   [SEQ]   Sent ENABLE for 8 cycles
UVM_INFO @ 115000:   [DRV]   Driving: enable=0 num_cycles=3
UVM_INFO @ 145000:   [SEQ]   Sent DISABLE for 3 cycles
UVM_INFO @ 145000:   [DRV]   Driving: enable=1 num_cycles=8
UVM_INFO @ 225000:   [SEQ]   Sent RE-ENABLE for 8 cycles
UVM_INFO @ 225000:   [DRV]   Driving: enable=0 num_cycles=3
UVM_INFO @ 255000:   [SEQ]   Sent IDLE for 3 cycles
UVM_INFO @ 255000:   [SEQ]   counter_sequence complete
UVM_INFO @ 255000:   [TEST]  === counter_test: PASSED ===
UVM_INFO @ 255000:   [TEST]  === UVM Report Phase: counter_test complete ===
UVM_INFO : 15 | UVM_WARNING : 0 | UVM_ERROR : 0 | UVM_FATAL : 0
$finish at simulation time 255000
```

---

## TRACK B — Verilator 5.046 (Open Source)

### Prerequisites

**1. Verilator 5.046** — build from source (requires GCC 13 for C++20 coroutines):
```bash
mkdir -p ~/local-tools
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH   # RHEL 8 only
cd ~/local-tools
git clone https://github.com/verilator/verilator.git
cd verilator
git checkout v5.046
autoconf
./configure --prefix=$HOME/local-tools \
    CXX=/opt/rh/gcc-toolset-13/root/usr/bin/g++ \
    CC=/opt/rh/gcc-toolset-13/root/usr/bin/gcc
make -j$(nproc)
make install
export PATH=$HOME/local-tools/bin:$PATH
verilator --version   # should print: Verilator 5.046
```

**2. uvm-verilator** (chipsalliance UVM fork):
```bash
cd ~/local-tools
git clone https://github.com/chipsalliance/uvm-verilator.git
```

### One-command build + run
```bash
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$HOME/local-tools/bin:$PATH
make -f Makefile.verilator
```

### Expected output
```
UVM_INFO @ 0:        [RNTST] Running test counter_test...
UVM_INFO @ 0:        [TEST]  === counter_test: run_phase starting ===
UVM_INFO @ 35000:    [DRV]   Driving: enable=1 num_cycles=8
UVM_INFO @ 115000:   [SEQ]   Sent ENABLE for 8 cycles
...
UVM_INFO @ 255000:   [TEST]  === counter_test: PASSED ===
UVM_INFO : 17 | UVM_WARNING : 2 | UVM_ERROR : 0 | UVM_FATAL : 0
- Verilator: $finish at 255ns
```

*(2 warnings are benign: `NO_DPI_USED` and `NO_VISIT_CHECK` — expected with `UVM_NO_DPI`)*

---

## Results

| | VCS U-2023.03-1 | Verilator 5.046 |
|---|---|---|
| UVM phases | All ran | All ran |
| Test result | PASSED | PASSED |
| Simulation time (ns) | 255 ns | 255 ns |
| Wall time (sim only) | 0.37 s | 0.013 s |
| UVM_ERROR | 0 | 0 |
| UVM_FATAL | 0 | 0 |
| Clocking blocks | ✓ Supported | ✗ Removed (workaround) |
| Covergroup in monitor | ✓ Supported | ✗ Removed (not supported) |
| Functional coverage | ✓ Collected | ✗ Not collected |

See [NOTES.md](NOTES.md) for full gap analysis and workaround documentation.

---

## Environment (tested on)
- **Server:** hansolo.poly.edu — RHEL 8.10, x86_64, 128 cores, 415 GB RAM
- **VCS:** U-2023.03-1 with `-full64` (Y-2026.03 is aarch64-only on this machine)
- **Verilator:** 5.046, built from source with GCC 13.3.1
- **UVM (VCS):** IEEE 1800.2-2020 (`uvm-ieee` bundled with VCS)
- **UVM (Verilator):** chipsalliance/uvm-verilator (Accellera 1800.2:UVM:2020.3.1)
- **GCC for Verilator C++ build:** 13.3.1 (gcc-toolset-13 via `/opt/rh/`)
