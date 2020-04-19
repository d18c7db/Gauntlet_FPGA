# Python 3.7.2
import argparse
import struct

parser = argparse.ArgumentParser(description='Reads a binary file and creates a VHDL ROM file that can be used for simulation.')
parser.add_argument('ifile',  type=argparse.FileType('rb'), help='source ROM binary file')
parser.add_argument('ofile',  type=argparse.FileType('wb'), help='destination ROM binary file')
args = parser.parse_args()

#seek to end
args.ifile.seek(0,2)
#get size of user binary file
bsize = args.ifile.tell()
#seek to start
args.ifile.seek(0,0)

data = args.ifile.read(bsize)

# Vindicators II ROM 2J has scrambled address lines, so for that one ROM, unscramble the data
print("Unscrambling ROM")
datatemp = bytearray(data)
for i in range(0, 0x8000):
	srcoffs = (i & 0x4000) | ((i << 11) & 0x3800) | ((i >> 3) & 0x07ff)
	datatemp[i] = ord(data[srcoffs:srcoffs+1])
data =bytes(datatemp)

args.ofile.write(data)

#close up files and exit
args.ifile.close()
args.ofile.close()
