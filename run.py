from vunit import VUnit

# Create VUnit instance by parsing command line args
vu = VUnit.from_argv()

# Create library "lib"
lib = vu.add_library("lib")

# Add component files and VUnit Testbenches to library "lib"
# #TODO: Eventually use blob pattern to include all? -> lib.add_source_files("./vhdl/*/*.vhd")
lib.add_source_files("./util/*.vhd")
lib.add_source_files("./DSP/arithmetic/adder_tree/hdl/adder_tree.vhd")
lib.add_source_files("./DSP/arithmetic/adder_tree/sim/tb_adder_tree.vhd")
lib.add_source_files("./DSP/CORDIC/rotation_mode/hdl/cordic.vhd")
lib.add_source_files("./DSP/CORDIC/rotation_mode/hdl/cordic_rot_scaled.vhd")
lib.add_source_files("./DSP/CORDIC/rotation_mode/sim/tb_cordic_rot_scaled.vhd")
lib.add_source_files("./DSP/CORDIC/vectoring_mode/hdl/cordic_vec.vhd")
lib.add_source_files("./DSP/CORDIC/vectoring_mode/hdl/cordic_vec_scaled.vhd")
lib.add_source_files("./DSP/CORDIC/vectoring_mode/sim/tb_cordic_vec_scaled.vhd")
lib.add_source_files("./memory-FIFO-SRL/RAM-ROM/single_port/sp_ram.vhd")

# GHDL options
#vu.set_compile_option("ghdl.flags", ["--std=08", "--enable-openieee"])
#vu.set_compile_option("ghdl.a_flags", ["--enable-openieee"])
#vu.set_compile_option("ghdl.flags", ["--ieee=synopsys", "-frelaxed-rules"])

# Run VUnit function
vu.main()

