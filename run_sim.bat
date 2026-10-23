@echo off
echo ===================================================
echo   Compiling 8-Point Pipelined FFT with Icarus Verilog
echo ===================================================
iverilog -o sim_fft.vvp complex_butterfly.v fft8_pipelined.v tb_fft8.v
if %errorlevel% neq 0 (
    echo [ERROR] Compilation failed!
    pause
    exit /b %errorlevel%
)

echo.
echo ===================================================
echo   Running Simulation and Logging Transcript
echo ===================================================
vvp sim_fft.vvp > simulation.log
type simulation.log

echo.
echo ===================================================
echo   Running Python Golden Reference & SQNR Analysis
echo ===================================================
python verify_fft.py

echo.
echo ===================================================
echo   Launching GTKWave for Waveform Inspection
echo ===================================================
start gtkwave fft8.vcd wave.gtkw
