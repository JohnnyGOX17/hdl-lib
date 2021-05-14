component=counter

all:
	iverilog -o tb_$(component) ./$(component).v ./tb_$(component).v
	vvp tb_$(component)

clean:
	rm -f tb_$(component)
