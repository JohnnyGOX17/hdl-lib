component=AXIS_reg_slice

all:
	iverilog -o tb_$(component) ./$(component).v ./tb_$(component).v
	# use LXT output format for VCDs https://iverilog.fandom.com/wiki/GTKWave
	vvp tb_$(component) -lxt2

clean:
	rm -f tb_$(component)
	rm -f *.vcd
