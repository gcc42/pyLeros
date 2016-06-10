from myhdl import block, Signal, intbv, instances, always_seq
import sys


@block
def pyleros_im(clk, reset, rd_addr, rd_data, filename = None):
	"""Definition of the instruction memory, or the ROM for
	pyleros. Reading is synchronous with the rising edge of the
	clock. Writing is not enabled.

	Arguments (ports):
        clk: The clock signal
        reset: The reset signal #Async?
        rd_addr: IN Read address
        rd_data: OUT The data at IM address

    Parameters:
	    None 

	"""
	IM_SIZE = 1024
	IM = [(intbv(0)[16:]) for _ in range(IM_SIZE)]

	# Fill up the memory registers
	define_rom(IM, IM_SIZE, filename)

	# convert list into tupple for automatic conversion
	IM_array = tuple(IM)

	@always_seq(clk.posedge, reset=reset)
	def IM_read():

			rd_data.next = IM[int(rd_addr)]

	return instances()




def define_rom(IM, IM_SIZE=1024, filename = None):

	if filename:
		if type(filename) is list:
			addr = 0
			for instr in filename:
				IM[addr] = intbv(instr)[16:]
				addr += 1

			for i in range(addr, IM_SIZE):
				IM[i] = intbv(0x0000)[16:]
			return 0

		with open(filename, "r") as f:
			addr = 0

			for line in f:
				line = line.split('//')[0]
				full = ''
				for part in line.split():
					full += part

				line = full
				if line:
					if not (line.isdigit() and (len(line) == 16)):
						raise Exception

					else:
						try:
							instr = intbv(int(line, 2))[16:]
							IM[addr] = instr
							addr += 1
						except:
							raise Exception

			for i in range(addr, IM_SIZE):

				IM[i] = intbv(0x0000)[16:]


	else:
		# Put the actual instructions here
		instruction_list = [ \
		"0x0000", 
		"0x0000", 
		"0x0000", 
		"0x0000", 
		"0x0000", 
		"0x0000", 
		"0x0000", 
		"0x0000", 
		"0x0000", 
		"0x0000", 
		"0x0000", 
		"0x0000", 
		"0x0000", 
		"0x0000", 
		"0x0000", 
		]

		for i in range(len(instruction_list)):
			IM[i] = (intbv(int(instruction_list[i],16))[16:])

		for i in range(len(instruction_list), IM_SIZE):
			IM[i] = (intbv(0x0000)[16:])


if __name__ == "__main__":

	if len(sys.argv) == 1:
		filename = None

	else:
		filename = sys.argv[1]

	IM_SIZE = 1024
	IM = [(intbv(0)[16:]) for _ in range(IM_SIZE)]


	# Fill up the memory registers
	define_rom(IM, IM_SIZE, filename)

	IM_array = tuple(IM)
	
	for addr in range(IM_SIZE):
		print(str(addr) + " : " + hex(IM[addr]))
