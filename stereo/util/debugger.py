import plotly.graph_objs as go
from plotly.subplots import make_subplots

import cv2
import numpy as np
import matplotlib.pyplot as plt
from PIL import Image


left_fp = '/Users/brianli/Desktop/6.111/stereo_test_images/bowling_left.png'
right_fp = '/Users/brianli/Desktop/6.111/stereo_test_images/bowling_right.png'
disparity_fp = "/Users/brianli/Desktop/6.111/anglerfish/stereo/data/disparity.mem"
disparity_values = []

# read in left/right image files
left_img = cv2.imread(left_fp, 0)
right_img = cv2.imread(right_fp, 0)
left_img = cv2.resize(left_img,  (240, 320))
right_img = cv2.resize(right_img, (240, 320))

# ready in disparity mem file
file = open(disparity_fp, "r")
while True:
	content=file.readline()
	if not content:
		break
	
	content = content.replace("\n","")
	disparity_values.append(content) 
file.close()


# get the disparity associated with pixel coord (r,c) as well as the associated left/right blocks
num_rows, num_cols = left_img.shape




def get_block(left_r, left_c, right_r, right_c, block_size=6, use_hex=False):
	left_block = left_img[left_r:left_r+block_size, left_c:left_c+block_size]
	right_block = right_img[right_r:right_r+block_size,right_c:right_c+block_size]

	print("SSD:", np.sum(np.abs(left_block-right_block)**2))
	print("(DEC) Left block  @ ({},{}):\n".format(left_r,left_c), left_block)
	print("(DEC)Right block @ ({},{}):\n".format(right_r,right_c), right_block)

	hex_func = np.vectorize(hex)
	left_block = hex_func(left_block)
	right_block = hex_func(right_block)

	print("(HEX) Left block  @ ({},{}):\n".format(left_r,left_c), left_block)
	print("(HEX) Right block @ ({},{}):\n".format(right_r,right_c), right_block)

get_block(0,0,0,0)
get_block(0,6,0,6)

def hexblock2ssd(left_block, right_block):
	ssd = 0
	for row in range(len(left_block)):
		left_pix_1 = int(left_block[row][0:2],16)
		left_pix_2 = int(left_block[row][2:4],16)
		left_pix_3 = int(left_block[row][4:6],16)
		left_pix_4 = int(left_block[row][6:8],16)
		left_pix_5 = int(left_block[row][8:10],16)
		left_pix_6 = int(left_block[row][10:],16)

		right_pix_1 = int(right_block[row][0:2],16)
		right_pix_2 = int(right_block[row][2:4],16)
		right_pix_3 = int(right_block[row][4:6],16)
		right_pix_4 = int(right_block[row][6:8],16)
		right_pix_5 = int(right_block[row][8:10],16)
		right_pix_6 = int(right_block[row][10:],16)

		left_row = np.array([left_pix_1, left_pix_2, left_pix_3, left_pix_4, left_pix_5, left_pix_6])
		right_row = np.array([right_pix_1, right_pix_2, right_pix_3, right_pix_4, right_pix_5, right_pix_6])
		ssd += np.sum(np.abs(left_row-right_row)**2)
	print("SSD from waveform:", ssd)

		


left_block = []
left_block.append("616062534F59")
left_block.append("63636257595D")
left_block.append("6161615C6462")
left_block.append("606868646A67")
left_block.append("696F746C7471")
left_block.append("646F7164606A")

right_block = []
right_block.append("62625F55565C")
right_block.append("6061605C6362")
right_block.append("626768636965")
right_block.append("676E716D7470")
right_block.append("616E70635C6C")
right_block.append("6E716F625865")

hexblock2ssd(left_block, right_block)




