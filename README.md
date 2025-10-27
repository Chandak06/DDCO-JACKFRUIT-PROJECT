Dual Elevator Controller (DDCO) - Simple Verilog model

This small project contains a simple dual-elevator controller modeled in Verilog for educational/testing purposes. It uses a naive partitioning scheduler for demonstration.

Files added:
- rtl/defs.vh - common parameter definitions
- rtl/elevator_car.v - simple elevator car FSM (movement + pending requests)
- rtl/dual_elevator_controller.v - top-level that assigns floors to two cars
- tb/dual_elevator_tb.v - testbench that generates calls, writes VCD waveform

Running simulation (Windows PowerShell):

# Install Icarus Verilog if not present: https://iverilog.fandom.com/wiki/Installing_Icarus_Verilog

# From project root
iverilog -o dual_elevator_tb.exe tb/dual_elevator_tb.v rtl/*.v; vvp dual_elevator_tb.exe

# View waveform
# Use GTKWave or other VCD viewer to open dual_elevator.vcd
