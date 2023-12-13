import serial
from PIL import Image

BAUD_RATE = 3000000
NUM_BYTES = 320 * 240 # note: this is number of bytes, which is number of bits / 8

ser = serial.Serial('/dev/ttyUSB1', BAUD_RATE) # CHANGE THIS TO MATCH COMPUTER'S PORT
from_fpga = ser.read(NUM_BYTES)

print(from_fpga)

def handle_as_rgb_image(data, width, height):
    im = Image.frombytes(mode='RGB', size=(width, height), data=data)
    im.save('rgb_image_from_bytes.jpg')
    return im

def print_out_binary(data, entries=1):
    bin_str = ''
    for byte in data:
        bin_str += f'{byte:0>8b}'
    for i in range(0, len(bin_str), int(len(bin_str) / entries)):
        print(bin_str[i:i + int(len(bin_str)/entries)])
    return bin_str

# you can handle the data other ways too, manipulating data with other functions

# example with image BRAM
# handle_as_rgb_image(from_fpga, 320, 240)
#print_out_binary(from_fpga, 320*240)
