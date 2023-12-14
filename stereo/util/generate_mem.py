import cv2
import numpy as np
import matplotlib.pyplot as plt
import binascii

# --------------
# Read in images
# --------------
# left_fp = '/Users/brianli/Desktop/6.111/stereo_test_images/bowling_left.png'
# right_fp = '/Users/brianli/Desktop/6.111/stereo_test_images/bowling_right.png'

left_fp = '/Users/brianli/Desktop/6.111/stereo_test_images/LEFT_TEST_PATTERN.png'
right_fp = '/Users/brianli/Desktop/6.111/stereo_test_images/RIGHT_TEST_PATTERN.png'

# left_fp = '/Users/brianli/Desktop/6.111/stereo_test_images/chair_left.jpg'
# right_fp = '/Users/brianli/Desktop/6.111/stereo_test_images/chair_right.jpg'

left_img = cv2.imread(left_fp, 0)
right_img = cv2.imread(right_fp, 0)

# --------------
# Downscale images to 320 rows x 240 cols
# --------------

# img1_rectified_downscaled = cv2.resize(left_img,  (320, 240))
# img2_rectified_downscaled = cv2.resize(right_img, (320, 240))

# img1_rectified_downscaled = cv2.resize(left_img,  (240, 320))
# img2_rectified_downscaled = cv2.resize(right_img, (240, 320))

img1_rectified_downscaled = left_img
img2_rectified_downscaled = right_img


print("img1 shape:")
print(img1_rectified_downscaled.shape)

print("img2 shape:")
print(img2_rectified_downscaled.shape)

block_size = 6

num_rows, num_cols = img1_rectified_downscaled.shape # NOTE: rows/cols are flipped
print(img1_rectified_downscaled[0])
with open('/Users/brianli/Desktop/6.111/anglerfish/stereo/data/left_image.mem', 'w') as file:
    for r in range(num_rows):
        counter = 0 # we are assuming that the num fo cols divides nicely by block size, otherwise addressing is more compliated
        temp = ""
        for c in range(num_cols):
            pixel_hex = hex(img1_rectified_downscaled[r, c])[2:] 
            if len(pixel_hex) == 1:
                pixel_hex = "0" + pixel_hex # all pixels should correspond to 2 digit hex number
            temp = temp + pixel_hex
            counter += 1
            if counter == block_size:
                file.write(temp + "\n")
                temp = ""
                counter = 0


num_rows, num_cols = img2_rectified_downscaled.shape # NOTE: rows/cols are flipped
with open('/Users/brianli/Desktop/6.111/anglerfish/stereo/data/right_image.mem', 'w') as file:
    for r in range(num_rows):
        counter = 0 # we are assuming that the num fo cols divides nicely by block size, otherwise addressing is more compliated
        temp = ""
        for c in range(num_cols):
            pixel_hex = hex(img2_rectified_downscaled[r,c])[2:] 
            if len(pixel_hex) == 1:
                pixel_hex = "0" + pixel_hex # all pixels should correspond to 2 digit hex number
            temp = temp + pixel_hex
            counter += 1
            if counter == block_size:
                file.write(temp + "\n")
                temp = ""
                counter = 0