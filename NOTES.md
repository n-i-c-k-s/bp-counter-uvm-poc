# UVM Testbench Gap Analysis: VCS vs Verilator

**DUT:** 8-bit up-counter (clk, rst_n, enable → count[7:0])  
**UVM Library (VCS):** IEEE 1800.2-2020 (`/eda/synopsys/vcs/U-2023.03-1/etc/uvm-ieee/`)  
**UVM Library (Verilator):** chipsalliance/uvm-verilator fork (Accellera 1800.2:UVM:2020.3.1)  
**Verilator:** v5.046  
**Server:** NYU RHEL 8.10 (hansolo.poly.edu), x86_64, 128 cores, GCC 8.5 / GCC 13.3

---

## What Works on VCS ✓

| Feature | Status | Notes |
|---|---|---|
| UVM phases (build/connect/run/report) | ✓ Works | All phases printed, correct order |
| `uvm_config_db` + virtual interface | ✓ Works | `set`/`get` with `virtual counter_if` |
| Clocking blocks in interface | ✓ Works | `driver_cb` and `monitor_cb` clocking blocks |
| UVM driver with clocking block refs | ✓ Works | `@(vif.driver_cb)`, `vif.driver_cb.enable <= ...` |
| UVM monitor with clocking block refs | ✓ Works | `@(vif.monitor_cb)`, sampling `.count` |
| UVM agent (driver + monitor + sequencer) | ✓ Works | Full agent hierarchy |
| UVM sequence + sequence item | ✓ Works | `rand` fields, `start_item`/`finish_item` |
| Constrained randomization | ✓ Works | `constraint reasonable_cycles { ... }` |
| `uvm_analysis_port` | ✓ Works | Monitor → agent port forwarded |
| Covergroup inside UVM monitor | ✓ Works | `count_cg` with `cp_count` and `cp_enable` bins |
| `+UVM_TESTNAME` plusarg | ✓ Works | Test selected by name |
| DPI for UVM regex / `uvm_reg` backdoor | ✓ Works | `uvm_dpi.cc` compiled |

**VCS simulation result:**
```
UVM_INFO : 15 | UVM_WARNING : 0 | UVM_ERROR : 0 | UVM_FATAL : 0
$finish at 255000 ps (255 ns)
```

---

## What Works on Verilator ✓

| Feature | Status | Notes |
|---|---|---|
| UVM phases (build/connect/run/report) | ✓ Works | Identical phase output to VCS |
| `uvm_config_db` + virtual interface | ✓ Works | Same `set`/`get` API |
| UVM driver with `@(posedge vif.clk)` | ✓ Works | Requires `--timing` flag |
| UVM monitor with `@(posedge vif.clk)` | ✓ Works | Direct edge-triggered sampling |
| UVM agent hierarchy | ✓ Works | Full `build_phase`/`connect_phase` |
| UVM sequence + sequence item | ✓ Works | `rand` fields compile fine |
| `uvm_analysis_port` | ✓ Works | Port connections elaborated correctly |
| `+UVM_TESTNAME` plusarg | ✓ Works | Parsed via `UVM_NO_DPI` path |
| `--timing` coroutine-based scheduling | ✓ Works | With GCC 13 (C++20 coroutines) |

**Verilator simulation result:**
```
UVM_INFO : 17 | UVM_WARNING : 2 | UVM_ERROR : 0 | UVM_FATAL : 0
$finish at 255ns (matches VCS to the nanosecond)
```

---

## What Required Workarounds on Verilator

### 1. Clocking Blocks — REMOVED
- **Problem:** Clocking blocks with `clocking driver_cb @(posedge clk)` in the interface, and `@(vif.driver_cb)` / `vif.driver_cb.signal <= ...` in the driver, cause elaboration failures in Verilator 5.046 with the uvm-verilator fork.
- **Workaround:** Created a separate `counter_if_verilator.sv` with no clocking blocks. Driver and monitor use `@(posedge vif.clk)` and direct `vif.signal = ...` assignments.
- **Impact:** No functional difference for this testbench. For real designs, clock-domain crossing assertions and default input/output skews of clocking blocks are lost.
- **Reference:** GettingVerilatorStartedWithUVM repo uses the same approach (no clocking blocks in `pipe_if.sv`).

### 2. Covergroup — REMOVED
- **Problem:** A covergroup (`count_cg`) inside a `uvm_monitor` class fails to compile under Verilator 5.046. Verilator's coverage model does not support covergroups nested inside parameterized or dynamic OOP classes from the UVM library.
- **Workaround:** Removed `count_cg` entirely from `counter_monitor_verilator.sv`. The `results/verilator_sim.log` notes the absence.
- **Impact:** Functional coverage is not collected in the Verilator run. For BlackParrot UVM, any `covergroup` inside a `uvm_monitor` or `uvm_scoreboard` will need to be either moved to a static module-level `covergroup` or replaced with Verilator's `--coverage-line`/`--coverage-toggle` RTL coverage.
- **Mitigation path:** Verilator's `--coverage` flag provides line and toggle coverage at the RTL level, which may satisfy GSoC coverage goals without SV functional covergroups.

### 3. GCC Version — REQUIRED GCC 13
- **Problem:** Verilator 5.x `--timing` mode generates C++ coroutines that require the `<coroutine>` header from C++20. RHEL 8's default GCC 8.5.0 does not support C++20.
- **Workaround:** Used GCC toolset 13 (`/opt/rh/gcc-toolset-13/`, GCC 13.3.1) which ships with RHEL 8 as an optional dev toolset. Added `GCC13_BIN` path prefix to `Makefile.verilator`.
- **Impact on GSoC:** Any CI/CD environment running BlackParrot UVM on Verilator will need GCC 11+ or Clang 12+ to use `--timing`. This is a deployment consideration, not a showstopper.

### 4. `UVM_NO_DPI` — Required
- **Problem:** The standard UVM `uvm_dpi.cc` DPI C code fails to compile with Verilator's generated C++ interface (wrong calling conventions, missing symbols).
- **Workaround:** `+define+UVM_NO_DPI` and `+define+UVM_REPORT_DISABLE_FILE_LINE` skip all DPI-dependent UVM code paths. The uvm-verilator fork has clean fallback paths for these defines.
- **Functional impact:** `uvm_hdl_read`/`uvm_hdl_force` (backdoor access), SV regex in component name checking, and file/line stamping on UVM messages are disabled. For a structural verification testbench these are not needed.

### 5. `/*verilator ...*/` Comment Syntax Conflict
- **Problem:** Multi-line comments starting with `/* verilator` are parsed by Verilator as internal pragma comments. The NOTES in source files triggered `%Error-BADVLTPRAGMA`.
- **Workaround:** Changed all multi-line prose comments to `//` single-line style.

---

## Verilator Limitations Found

| Limitation | Severity | Mitigation |
|---|---|---|
| No covergroup in UVM classes | High | Use RTL-level `--coverage` or module-level covergroups |
| No clocking block support with UVM | Medium | Replace with `@(posedge clk)` + direct signal drives |
| Requires GCC 11+ / C++20 for `--timing` | Medium | Use gcc-toolset-13 on RHEL 8; non-issue on Ubuntu 22.04+ |
| `UVM_NO_DPI` disables backdoor access | Medium | Acceptable for structural/functional TB |
| No `uvm_hdl_force` / `uvm_hdl_read` | Medium | Use direct SV hierarchical references instead |
| Long verilation time (~3 min for UVM) | Low | One-time cost; simulation itself is 0.013 s |
| `/*verilator*/` pragma collision | Low | Use `//` comments in TB source |

---

## Performance Comparison

| Metric | VCS U-2023.03-1 | Verilator 5.046 |
|---|---|---|
| Compile time | ~9 s (compile+elab+link) | ~200 s fresh; ~30 s with warm ccache |
| Simulation time | 0.370 s | 0.013 s |
| Simulation speed | — | ~28x faster than VCS |
| Binary size | 1.8 MB (simv_vcs) | 20 MB (Vuvm_pkg) |
| Memory (sim) | ~0.2 MB reported | ~32 MB allocated |

*Verilator simulates ~28x faster than VCS for this testbench once compiled.*

---

## Relevance to GSoC: BlackParrot UVM Testbenches in Verilator

1. **The core UVM flow works:** phases, sequences, agents, config_db, virtual interfaces, analysis ports — all confirmed functional on Verilator 5.046.
2. **Two critical gaps for BlackParrot:** clocking blocks and covergroups. Both have known workarounds that are acceptable for an open-source verification project.
3. **DPI limitation** blocks `uvm_reg` backdoor access — a real constraint if BlackParrot needs register-level stimulus. Direct SV references can substitute.
4. **The build complexity** (uvm-verilator fork, GCC 13, specific Verilator flags) is real but manageable as a one-time setup — exactly the kind of tooling that a GSoC project would standardize and document.
