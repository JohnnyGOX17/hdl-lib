from vunit import VUnit

# Create VUnit instance by parsing command line args
vu = VUnit.from_argv()

# Create library "lib"
lib = vu.add_library("lib")

# Add all files ending in *.vhd to library "lib"
#lib.add_source_files("./vhdl/*/*.vhd")
lib.add_source_files("./memory-FIFO-SRL/RAM-ROM/*.vhd")

# GHDL options
#vu.set_compile_option("ghdl.flags", ["--std=08", "--enable-openieee"])
#vu.set_compile_option("ghdl.a_flags", ["--enable-openieee"])
#vu.set_compile_option("ghdl.flags", ["--ieee=synopsys", "-frelaxed-rules"])

# Run VUnit function
vu.main()

