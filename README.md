# Pipelined 8-Point Radix-2 DIF FFT Hardware Accelerator

![Verilog](https://img.shields.io/badge/Language-Verilog-blue.svg)
![Simulation](https://img.shields.io/badge/Simulation-Icarus%20Verilog%20%7C%20GTKWave-brightgreen.svg)
![Verification](https://img.shields.io/badge/Verification-Python%20NumPy%20Golden%20Model-yellowgreen.svg)
![Synthesis](https://img.shields.io/badge/Synthesis-AMD%20Vivado-orange.svg)
![License](https://img.shields.io/badge/License-MIT-lightgrey.svg)

A high-throughput, fully pipelined **8-Point Radix-2 Decimation-in-Frequency (DIF) Fast Fourier Transform (FFT)** hardware accelerator designed in Verilog HDL. The core computes complex frequency spectra in real time with continuous streaming throughput (1 complex vector per clock cycle).

Implemented with **16-bit signed Q1.14 fixed-point arithmetic**, stage-by-stage $1/2$ scaling to guarantee zero arithmetic overflow, and an internal bit-reversal unscrambler to output natural frequency bins $X[0] \dots X[7]$.

---

## 📌 Architecture & Microarchitecture

```
                      fft8_pipelined.v (Top-Level Datapath)
+-----------------------------------------------------------------------------------+
|                                                                                   |
|  x0..x7 (Inputs)                                                                  |
|       │                                                                           |
|       ▼                                                                           |
|  ┌──────────────────┐                                                             |
|  │ STAGE 1 (Dist=4) │──► [ Pipe Reg 1 ]                                           |
|  │ 4 Butterflies    │                                                             |
|  └──────────────────┘          │                                                  |
|                                ▼                                                  |
|                       ┌──────────────────┐                                        |
|                       │ STAGE 2 (Dist=2) │──► [ Pipe Reg 2 ]                      |
|                       │ 4 Butterflies    │                                        |
|                       └──────────────────┘          │                             |
|                                                     ▼                             |
|                                            ┌──────────────────┐                   |
|                                            │ STAGE 3 (Dist=1) │──► [ Pipe Reg 3 ] |
|                                            │ 4 Butterflies    │                   |
|                                            └──────────────────┘          │        |
|                                                                          ▼        |
|                                                                ┌────────────────┐ |
|                                                                │ Bit-Reversal   │ |
|                                                                │ Unscrambler    │ |
|                                                                └────────┬───────┘ |
|                                                                         │         |
|                                                                         ▼         |
|                                                            X0..X7 (Natural Bins)  |
|                                                            out_valid = 1          |
|                                                                                   |
+-----------------------------------------------------------------------------------+
```

### Pipelining & Latency
* **Pipeline Depth:** 3 synchronous stages (1 cycle per butterfly stage).
* **Latency:** Exactly **3 clock cycles** from `in_valid` to `out_valid`.
* **Throughput:** **1 complex vector per clock cycle** (continuous single-cycle streaming).

---

## 🔑 Mathematical Derivation & Fixed-Point Precision

### 1. Radix-2 Decimation-in-Frequency (DIF)
The 8-point Discrete Fourier Transform (DFT) is defined as:
$$X[k] = \sum_{n=0}^{7} x[n] W_8^{nk}, \quad W_8 = e^{-j \frac{2\pi}{8}} = \frac{\sqrt{2}}{2} - j \frac{\sqrt{2}}{2}$$

In DIF decomposition:
* **Stage 1 ($N=8$):** Butterfly distance $= 4$. Twiddles: $W_8^0, W_8^1, W_8^2, W_8^3$.
* **Stage 2 ($N=4$):** Butterfly distance $= 2$. Twiddles: $W_8^0, W_8^2$.
* **Stage 3 ($N=2$):** Butterfly distance $= 1$. Twiddles: $W_8^0$.

### 2. Complex Butterfly Unit (`complex_butterfly.v`)
For inputs $A$ and $B$ with twiddle factor $W$:
$$X = \frac{A + B}{2}$$
$$Y = \frac{(A - B) \cdot W}{2}$$

### 3. Overflow Prevention & Q1.14 Number System
* Numbers are represented in **16-bit signed Q1.14 format**:
  * Bit 15: Sign bit
  * Bit 14: Integer bit
  * Bits 13–0: 14 Fractional bits ($1.0 = 16384$, $\frac{\sqrt{2}}{2} \approx 11585$).
* **Stage-by-stage scaling:** An arithmetic right-shift (`>>> 1`) is applied at every butterfly addition and difference. This guarantees mathematically that dynamic range never exceeds $[-2.0, +1.999]$, preventing overflow without requiring expensive floating-point hardware.

---

## 📊 Port List

| Port Name | Direction | Type | Width | Description |
| :--- | :---: | :---: | :---: | :--- |
| `clk` | Input | Wire | 1 | Master system clock (up to 250+ MHz) |
| `rst_n` | Input | Wire | 1 | Asynchronous active-low reset |
| `in_valid` | Input | Wire | 1 | Input sample valid handshake |
| `x0_re .. x7_re` | Input | Wire | 16 | Real channels of input samples $x[0] \dots x[7]$ |
| `x0_im .. x7_im` | Input | Wire | 16 | Imaginary channels of input samples $x[0] \dots x[7]$ |
| `out_valid` | Output | Reg | 1 | Output valid flag (asserts 3 cycles after input) |
| `X0_re .. X7_re` | Output | Reg | 16 | Real channels of frequency bins $X[0] \dots X[7]$ |
| `X0_im .. X7_im` | Output | Reg | 16 | Imaginary channels of frequency bins $X[0] \dots X[7]$ |

---

## 🧪 Verification & Simulation

### 1. Test Suite Scenarios (`tb_fft8.v`)
1. **DC Signal Test ($x[n] = 1.0$):** Validates that all signal energy concentrates 100% in Bin 0 ($X[0] = 16384$), while Bins 1–7 are zero.
2. **Unit Impulse Test ($x[0] = 1.0$, rest $= 0$):** Validates a flat frequency response across all bins ($X[k] = 2048 = 1/8$ in Q1.14).
3. **Single-Tone Sine Wave ($e^{j 2\pi \cdot 1 \cdot n / 8}$):** Validates sharp spectral peak detection at Bin 1.

### 2. Python Golden Model & SQNR (`verify_fft.py`)
A Python verification script evaluates 100 random complex signals against NumPy's floating-point FFT:
* **Measured SQNR (Signal-to-Quantization-Noise Ratio):** **> 55 dB** (industry standard for 16-bit DSP).

### 3. Simulation Transcript (`simulation.log`)
```text
============================================================
    STARTING 8-POINT PIPELINED RADIX-2 DIF FFT TEST         
    Architecture: 3-Stage Synchronous Pipeline              
    Precision: 16-bit Signed Q1.14 Fixed-Point              
============================================================

--- TEST 1: Constant DC Signal (x[n] = 1.0) ---
[INFO @ 85000 ns] Output Valid Asserted! Checking DC response...
[PASS] TEST 1: DC Energy 100% concentrated in Bin 0 (X0_re=16384, X1..7=0)

--- TEST 2: Checking Unit Impulse Response ---
[PASS] TEST 2: Flat impulse frequency response (All bins exactly 2048 / Q1.14)

--- TEST 3: Checking Single-Tone Sine Wave (Bin 1) ---
[PASS] TEST 3: Strong spectral peak cleanly detected at Bin 1 (Mag^2=268403569)

============================================================
   *** ALL 8-POINT FFT TESTS PASSED WITH ZERO ERRORS! ***   
   Pipeline Latency: Exactly 3 Cycles                       
   Throughput: 1 Complex Vector / Clock Cycle               
   Waveform generated: fft8.vcd                             
============================================================
```

### How to Run Simulation (1-Click)
```cmd
run_sim.bat
```
Or manually:
```bash
iverilog -o sim_fft.vvp complex_butterfly.v fft8_pipelined.v tb_fft8.v
vvp sim_fft.vvp
python verify_fft.py
gtkwave fft8.vcd wave.gtkw
```

---

## 🛠️ FPGA Synthesis & Implementation (AMD Vivado)

* **Target Device:** AMD / Xilinx Artix-7 (`xc7a35tcsg324-1`)
* **Timing Constraint:** 250 MHz ($T_{clk} = 4.0\text{ ns}$)
* **Timing Slack:** Positive setup and hold margins (Timing Met with 0 violations)
* **Resource Utilization:**
  * **LUTs:** ~180
  * **Flip-Flops:** ~260
  * **DSP48 Slices:** 16 (4 complex multipliers across Stage 1 and 2)
  * **Max Clock Frequency ($F_{max}$):** **> 250 MHz**

---

## 📜 References
* J. W. Cooley and J. W. Tukey, *"An algorithm for the machine calculation of complex Fourier series"*, Math. Comput., 1965.
* A. V. Oppenheim and R. W. Schafer, *Discrete-Time Signal Processing*, Prentice Hall.

---

## 👤 Author
* **Shivam Sikri**
* GitHub: [@ShivamSikri03](https://github.com/ShivamSikri03)
