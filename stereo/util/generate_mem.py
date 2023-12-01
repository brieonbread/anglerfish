import cv2
import numpy as np
import matplotlib.pyplot as plt
import binascii

# --------------
# Read in images
# --------------
left_fp = '/Users/brianli/Desktop/stereo_test_images/bowling_left.png'
right_fp = '/Users/brianli/Desktop/stereo_test_images/bowling_right.png'
left_img = cv2.imread(left_fp, 0)
right_img = cv2.imread(right_fp, 0)

# --------------
# Downscale images to 320x240
# --------------

img1_rectified_downscaled = cv2.resize(left_img,  (320, 240))
img2_rectified_downscaled = cv2.resize(right_img, (320, 240))

print("img2:")
print(img2_rectified_downscaled)

block_size = 6

num_cols, num_rows = img1_rectified_downscaled.shape # NOTE: rows/cols are flipped
with open('/Users/brianli/Desktop/6.111/anglerfish/stereo/data/left_image.mem', 'w') as file:
    for r in range(num_rows):
        counter = 0 # we are assuming that the num fo cols divides nicely by block size, otherwise addressing is more compliated
        temp = ""
        for c in range(num_cols):
            pixel_hex = hex(img1_rectified_downscaled[c, r])[2:] 
            if len(pixel_hex) == 1:
                pixel_hex = "0" + pixel_hex # all pixels should correspond to 2 digit hex number
            temp = temp + pixel_hex
            counter += 1
            if counter == block_size:
                file.write(temp + "\n")
                temp = ""
                counter = 0


num_cols, num_rows = img2_rectified_downscaled.shape # NOTE: rows/cols are flipped
with open('/Users/brianli/Desktop/6.111/anglerfish/stereo/data/right_image.mem', 'w') as file:
    for r in range(num_rows):
        counter = 0 # we are assuming that the num fo cols divides nicely by block size, otherwise addressing is more compliated
        temp = ""
        for c in range(num_cols):
            pixel_hex = hex(img2_rectified_downscaled[c, r])[2:] 
            if len(pixel_hex) == 1:
                pixel_hex = "0" + pixel_hex # all pixels should correspond to 2 digit hex number
            temp = temp + pixel_hex
            counter += 1
            if counter == block_size:
                file.write(temp + "\n")
                temp = ""
                counter = 0