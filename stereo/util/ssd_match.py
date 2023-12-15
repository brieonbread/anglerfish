import cv2
import numpy as np
import matplotlib.pyplot as plt
import time

def compute_sad(left_rectified, right_rectified, left_pixel, right_pixel, block_size):
    """
    Notes: Assumes valid left_pixel and right_pixel are given (i.e. won't result in indexing out of bounds)
    Params:
        left_rectified (numpy 2d array): 320*240 grayscale image corresponding to left stereo camera
        right_rectified (numpy 2d array): 320*240 grayscale image corresponding to right stereo camera
        left_pixel (tuple): a tuple in the form (row, col) indicating which pixel the window for left image is centered on
        right_pixel (tuple): a tuple in the form (row, col) indicating which pixel the window for right image is centered on
        block_size (int): the size of window we are using to compare features between left and right image
    Returns:
        a float, the sad metric that corresponds to taking block centered at left_pixel and block centered at right_pixel
        with the given block size 
    """
    left_row, left_col = left_pixel
    right_row, right_col = right_pixel

    left_subset = left_rectified[left_row:left_row+block_size, left_col:left_col+block_size]
    right_subset = right_rectified[right_row:right_row+block_size, right_col:right_col+block_size]

    return np.sum((left_subset-right_subset)**2)

def sad_disparity(left_rectified, right_rectified, block_size=0, max_offset=0):
    """
    Params:
        left_rectified (numpy 2d array): 320*240 grayscale image corresponding to left stereo camera
        right_rectified (numpy 2d array): 320*240 grayscale image corresponding to right stereo camera
        block_size (int): the size of window we are using to compare features between left and right image
        max_offset (int): the greatest expected distance (in pixels) between a corresponding feature in left and right image 
    Returns: 
        numpy 2d array: 320x240
    """

    disparity_map = np.zeros_like(left_rectified)
    num_rows, num_cols = left_rectified.shape
    # max_offset = num_cols - block_size

    left_min_x = 0
    left_max_x = num_cols - block_size
    left_min_y = 0
    left_max_y = num_rows - block_size

    right_min_x = 0 
    right_max_x = num_cols - block_size
    right_min_y = 0
    right_max_y = num_rows - block_size

    
    for r in range(left_min_y, left_max_y):
        print("r ", r)
        # if r == 1:
        #     break
        for c in range(left_min_x, left_max_x):
            # if c == 30:
            #     break
            # print("row = {}, col = {}:".format(r, c))


            temp_disparities = [] # for debug
            min_sofar = float('inf')
            min_offset = 0
            # for offset in range(block_width, num_cols-block_width):
            for offset in range(max_offset):
                # print("offset", offset)
                # print("(r, c): ({}, {})".format(r, c))
                if c - offset >= 0:
                    left_pixel = (r, c)
                    right_pixel = (r, c-offset)
                    # print('left pixel', left_pixel)
                    # print('right_pixel', right_pixel)
                    result = compute_sad(left_rectified, right_rectified, left_pixel, right_pixel, block_size)
                    # print("ssd result", result)
                    if result < min_sofar:
                        min_sofar = result
                        min_offset = offset # for saving disparity
                        
            disparity_map[r,c] = min_offset # for saving disparity
            # disparity_map[r,c] = min_sofar if min_sofar != float('inf') else 0  # for saving ssd

    return disparity_map


# --------------
# Read in images
# --------------
# left_fp = '/Users/brianli/Desktop/6.111/stereo_test_images/bowling_left.png'
# right_fp = '/Users/brianli/Desktop/6.111/stereo_test_images/bowling_right.png'

# left_fp = '/Users/brianli/Desktop/6.111/stereo_test_images/LEFT_TEST_PATTERN.png'
# right_fp = '/Users/brianli/Desktop/6.111/stereo_test_images/RIGHT_TEST_PATTERN.png'

left_fp = '/Users/brianli/Desktop/6.111/stereo_test_images/chair_left.jpg'
right_fp = '/Users/brianli/Desktop/6.111/stereo_test_images/chair_right.jpg'


left_img = cv2.imread(left_fp, 0)
right_img = cv2.imread(right_fp, 0)

# plt.imshow(left_img, cmap='gray')
# plt.show()
# plt.imshow(right_img, cmap='gray')
# plt.show()

# ----------------
# Downscale images
# ----------------

# img1_rectified_downscaled = cv2.resize(img1_rectified, (320, 240))
# img2_rectified_downscaled = cv2.resize(img2_rectified, (320, 240))

# img1_rectified_downscaled = cv2.resize(left_img,  (320, 240))
# img2_rectified_downscaled = cv2.resize(right_img, (320, 240))

# img1_rectified_downscaled = cv2.resize(left_img,  (240, 320))
# img2_rectified_downscaled = cv2.resize(right_img, (240, 320))

img1_rectified_downscaled = left_img
img2_rectified_downscaled = right_img

# plt.imshow(img1_rectified_downscaled, cmap='gray')
# plt.title("Image shape: {}".format(img1_rectified_downscaled.shape))
# plt.show()

# img1_rectified_downscaled = cv2.resize(left_img,  (240, 320))
# img2_rectified_downscaled = cv2.resize(right_img, (240, 320))

img1_rectified_downscaled = img1_rectified_downscaled.astype(np.uint32)
img2_rectified_downscaled = img2_rectified_downscaled.astype(np.uint32)

max_offset = 240
# max_offset = 30
block_size = 6

start = time.time()
disparity_map = sad_disparity(img1_rectified_downscaled , img2_rectified_downscaled, block_size=block_size, max_offset=max_offset)
# disparity_map = disparity_map * (255/max_offset)
end = time.time()
print("Elapsed Time:", end-start)

print(disparity_map[0][120:135])
bram_block_size = 1
# Save disparity into as mem files as hex values
num_rows, num_cols = disparity_map.shape # NOTE: rows/cols are flipped
with open('/Users/brianli/Desktop/6.111/anglerfish/stereo/data/disparity.mem', 'w') as file:
    for r in range(num_rows):
        counter = 0 # we are assuming that the num fo cols divides nicely by block size, otherwise addressing is more compliated
        temp = ""
        for c in range(num_cols):
            # pixel_hex = hex(disparity_map[r, c])[2:] # save as hex
            pixel_hex = str(disparity_map[r, c]) # save as dec
            # if len(pixel_hex) == 1:
            #     pixel_hex = "0" + pixel_hex # all pixels should correspond to 2 digit hex number
            temp = temp + pixel_hex
            counter += 1
            if counter == bram_block_size:
                file.write(temp + "\n")
                temp = ""
                counter = 0
    print("Saved disparity map to disparity.mem")

# Only plot disparity
plt.imshow(disparity_map, cmap='gray')
plt.title("Block Size = {}, Max Offset = {}".format(block_size, max_offset))
plt.colorbar()
plt.show()


# Put everything on a single plot
fig, axes = plt.subplots(nrows=1, ncols=3, figsize=(15, 10))
axes[0].imshow(img1_rectified_downscaled, cmap='plasma')
axes[0].set_title("Left Rectified")

axes[1].imshow(img2_rectified_downscaled, cmap='plasma')
axes[1].set_title("Right Rectified")

axes[2].imshow(disparity_map, cmap='plasma')
axes[2].set_title("Block Size = {}, Max Offset = {}".format(block_size, max_offset))

plt.show()




