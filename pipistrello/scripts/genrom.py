# Python 3.7.2
import argparse

parser = argparse.ArgumentParser(description='Reads a binary file and creates a VHDL ROM file that can be used for simulation.')
parser.add_argument('src',  type=argparse.FileType('rb'), help='source ROM binary file')
parser.add_argument('entity', type=str, help='entity name')
parser.add_argument('dst',  type=argparse.FileType('wt'), help='destination VHDL file')
args = parser.parse_args()

#seek to end
args.src.seek(0,2)
#get size of user binary file
bsize = args.src.tell()
#seek to start
args.src.seek(0,0)

bits = (bsize-1).bit_length()
assert bits <= 16, "File too large to generate VHDL memory structure"
assert bsize == (2**bits), "File alignment error, size is not a power of 2"

print(f'Generating {args.entity:8} of size {bsize:5d}')

args.dst.write("library ieee;\n")
args.dst.write("\tuse ieee.std_logic_1164.all;\n")
args.dst.write("\tuse ieee.numeric_std.all;\n")
args.dst.write("\n")
#args.dst.write("library UNISIM;\n")
#args.dst.write("\tuse UNISIM.Vcomponents.all;\n")
#args.dst.write("\n")
args.dst.write("entity %s is\n" %args.entity)
args.dst.write("port (\n")
args.dst.write("\tCLK  : in  std_logic;\n")
args.dst.write("\tADDR : in  std_logic_vector(%d downto 0);\n" %(bits-1))
args.dst.write("\tDATA : out std_logic_vector(7 downto 0) := (others=>'0')\n")
args.dst.write("\t);\n")
args.dst.write("end entity;\n")
args.dst.write("\n")
args.dst.write("architecture RTL of %s is\n" %args.entity)
args.dst.write("\ttype ROM_ARRAY is array (0 to %d) of std_logic_vector(7 downto 0);\n" %(bsize-1))
args.dst.write("\tsignal ROM : ROM_ARRAY := (\n")

data = args.src.read()
counter = 0
args.dst.write("\t\t")
while counter < bsize-1:
	args.dst.write("x\"%s\"," %(data[counter:counter+1].hex().upper()))
	counter = counter + 1
	if counter%16 == 0:
		args.dst.write(" -- 0x%04X\n\t\t" %(counter-16))

#last entry has no comma
args.dst.write("x\"%s\"  -- 0x%04X" %((data[counter:counter+1].hex().upper()), (counter-15)) )

args.dst.write("\n\t);\n")
args.dst.write("\tattribute ram_style : string;\n")
#distributed, block, auto
args.dst.write("\tattribute ram_style of ROM : signal is ")
if bsize > 1023:
	args.dst.write("\"block\";\n")
else:
	args.dst.write("\"auto\";\n")
args.dst.write("begin\n")
args.dst.write("\tmem_proc : process\n")
args.dst.write("\tbegin\n")
args.dst.write("\t\twait until rising_edge(CLK);\n")
args.dst.write("\t\tDATA <= ROM(to_integer(unsigned(ADDR)));\n")
args.dst.write("\tend process;\n")
args.dst.write("end RTL;\n")

#close up files and exit
args.src.close()
args.dst.close()
