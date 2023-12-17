import serial

ser = ser.Serial('/dev/ttyUSB1', 3000000)
ser.write(bytes(1))
from_fpga = ser.read(1)

print(str(from_fpga))
