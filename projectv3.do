# Set the working dir, where all compiled Verilog goes.
vlib work
 
# Compile all verilog modules in mux.v to working dir;
# could also have multiple verilog files.
vlog projectv3.v
 
# Load simulation using mux as the top level simulation module.
vsim projectv3
 
# Log all signals and add some signals to waveform window.
log {/*}
# add wave {/*} would add all items in top level simulation module.
add wave {/*}
 
# First test case
# Set input values using the force command, signal names need to be in {} brackets.
force {CLOCK_50} 0 0, 1 1 -repeat 2
#CLOCK
 
force {KEY[0]} 0
force {KEY[1]} 0
#left
force {KEY[2]} 0
#up
force {KEY[3]} 0
#down
force {KEY[4]} 0
#right
force {SW[0]} 1
#restart
force {SW[1]} 0
#EVERYTHING to zero
 
run 1000 ns
 
force {SW[0]} 0
#reset
 
run 35400 ns
 
 
force {SW[1]} 1
 #restart
run 1000 ns
 
force {SW[1]} 0
 
run 35400 ns
 
force {SW[1]} 1
 #restart
run 1000 ns
 
force {SW[1]} 0
 
run 35400 ns
 
force {KEY[3]} 1
 #move left sun
run 35400 ns
 
force {KEY[3]} 0
 
run 3000 ns
 
force {KEY[3]} 1
 #move left sun
run 35400 ns
 
force {KEY[3]} 0
 
run 3000 ns

force {KEY[3]} 1
 #move left sun
run 35400 ns
 
force {KEY[3]} 0
 
run 3000 ns

