vlib work
vlog reg_mux.v dsp48a1.v dsp_tb.v
vsim -voptargs=+acc work.dsp_tb
add wave *
run -all
#quit -sim