# -*- coding: UTF-8 -*-
print("\n    You can create a file any size.\n")
print("    MB as default unit.\n")

raw_num=input("    Enter file size:").upper()

a=raw_num.upper().find('G')
unit=0

if a == -1:
    a=raw_num.upper().find('M')
    unit=1

if a > 0:
    size=raw_num[:a].strip()
else:
    size=raw_num.strip()

if unit == 1:
    filesize=1024*1024*float(size)
elif unit == 0:
    filesize=1024*1024*1024*float(size)

def gen_file(path,size):  
    file = open(path,'w')  
    file.seek(filesize)
    file.write('\x00')  
    file.close()  
      
gen_file('./test.dat',size)
