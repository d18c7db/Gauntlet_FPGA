# Python 3.7.2
import argparse
import struct

parser = argparse.ArgumentParser(description='Reads a binary file and creates a VHDL ROM file that can be used for simulation.')
parser.add_argument('ifile',  type=argparse.FileType('rb'), help='source ROM binary file')
parser.add_argument('entity', type=str, help='entity name')
parser.add_argument('ofile',  type=argparse.FileType('wt'), help='destination VHDL file')
args = parser.parse_args()

#seek to end
args.ifile.seek(0,2)
#get size of user binary file
bsize = args.ifile.tell()
#seek to start
args.ifile.seek(0,0)

bits = bsize-1
counter = 0
while bits>1:
	bits>>=1
	counter = counter + 1

fsize_pow2 = (2**(counter+1))
remainder = fsize_pow2 - bsize
print(f'Generating {args.entity:8} of size {fsize_pow2:5d}')

assert bsize <= 64*1024, "File too large for practical simulation"
args.ofile.write("library ieee;\n")
args.ofile.write("\tuse ieee.std_logic_1164.all;\n")
#args.ofile.write("\tuse ieee.std_logic_arith.all;\n")
#args.ofile.write("\tuse ieee.std_logic_unsigned.all;\n")
args.ofile.write("\tuse ieee.numeric_std.all;\n")
args.ofile.write("\n")
#args.ofile.write("library UNISIM;\n")
#args.ofile.write("\tuse UNISIM.Vcomponents.all;\n")
#args.ofile.write("\n")
args.ofile.write("entity %s is\n" %args.entity)
args.ofile.write("port (\n")
args.ofile.write("\tCLK  : in  std_logic;\n")
args.ofile.write("\tADDR : in  std_logic_vector(%d downto 0);\n" %counter)
args.ofile.write("\tDATA : out std_logic_vector(7 downto 0) := (others=>'0')\n")
args.ofile.write("\t);\n")
args.ofile.write("end entity;\n")
args.ofile.write("\n")
args.ofile.write("architecture RTL of %s is\n" %args.entity)
args.ofile.write("\ttype ROM_ARRAY is array (0 to %d) of std_logic_vector(7 downto 0);\n" %(fsize_pow2-1))
args.ofile.write("\tsignal ROM : ROM_ARRAY := (\n")

counter = 0
args.ofile.write("\t\t")
while counter < bsize-1:
	data = args.ifile.read(1)
	(n,) = struct.unpack(">B", data)
	args.ofile.write("x"'"%02X"'"," %n)
	counter = counter + 1
	if counter%16 == 0:
		args.ofile.write(" -- 0x%04X\n\t\t" %(counter-16))

#last entry has no comma
data = args.ifile.read(1)
(n,) = struct.unpack(">B", data)
args.ofile.write("x"'"%02X"'"  -- 0x%04X" %(n, (counter-15)) )
counter = counter + 1

#unless remainder > 0
#if remainder>0:
#	args.ofile.write(",")
#
#	while counter < bsize+remainder-1:
#		if counter%16 == 0:
#			args.ofile.write("\n\t\t")
#		args.ofile.write("x"'"00"'",")
#		counter = counter + 1
#
#last entry has no comma
#	args.ofile.write("x"'"00"'"")

args.ofile.write("\n\t);\n")
args.ofile.write("\tattribute ram_style : string;\n")
#distributed, block, auto
args.ofile.write("\tattribute ram_style of ROM : signal is ")
if bsize > 1000:
	args.ofile.write("\"block\";\n")
else:
	args.ofile.write("\"auto\";\n")
args.ofile.write("begin\n")
args.ofile.write("\tmem_proc : process\n")
args.ofile.write("\tbegin\n")
args.ofile.write("\t\twait until rising_edge(CLK);\n")
args.ofile.write("\t\tDATA <= ROM(to_integer(unsigned(ADDR)));\n")
args.ofile.write("\tend process;\n")
args.ofile.write("end RTL;\n")

#close up files and exit
args.ifile.close()
args.ofile.close()
