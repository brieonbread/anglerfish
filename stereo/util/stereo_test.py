import cv2
import numpy as np
import matplotlib.pyplot as plt

# --------------
# Read in images
# --------------
left_fp = '/Users/brianli/Desktop/stereo_test_images/lab_full_left.jpg'
right_fp = '/Users/brianli/Desktop/stereo_test_images/lab_full_right.jpg'
left_img = cv2.imread(left_fp, 0)
# plt.imshow(left_img, cmap='gray')
# plt.show()
right_img = cv2.imread(right_fp, 0)
# plt.imshow(right_img, cmap='gray')
# plt.show()

"""
# --------------------------------------------------------
# Initiate SIFT detector to detect keypoints in L/R images
# --------------------------------------------------------
sift = cv2.SIFT_create()
# find the keypoints and descriptors with SIFT
kp1, des1 = sift.detectAndCompute(left_img, None)
kp2, des2 = sift.detectAndCompute(right_img, None)

imgSift = cv2.drawKeypoints(
    left_img, kp1, None, flags=cv2.DRAW_MATCHES_FLAGS_DRAW_RICH_KEYPOINTS)

# cv2.imshow("SIFT Keypoints", imgSift)
# cv2.waitKey(0)
# cv2.destroyAllWindows()

# -------------------------------------------
# Match corresponding keypoints in L/R images
# -------------------------------------------
# Based on: https://docs.opencv.org/master/dc/dc3/tutorial_py_matcher.html
FLANN_INDEX_KDTREE = 1
index_params = dict(algorithm=FLANN_INDEX_KDTREE, trees=5)
search_params = dict(checks=50)   # or pass empty dictionary
flann = cv2.FlannBasedMatcher(index_params, search_params)
matches = flann.knnMatch(des1, des2, k=2)

# Keep good matches: calculate distinctive image features
# Lowe, D.G. Distinctive Image Features from Scale-Invariant Keypoints. International Journal of Computer Vision 60, 91–110 (2004). https://doi.org/10.1023/B:VISI.0000029664.99615.94
# https://www.cs.ubc.ca/~lowe/papers/ijcv04.pdf
matchesMask = [[0, 0] for i in range(len(matches))]
good = []
pts1 = []
pts2 = []

for i, (m, n) in enumerate(matches):
    if m.distance < 0.7*n.distance:
        # Keep this keypoint pair
        matchesMask[i] = [1, 0]
        good.append(m)
        pts2.append(kp2[m.trainIdx].pt)
        pts1.append(kp1[m.queryIdx].pt)


# Draw the keypoint matches between both pictures
# Still based on: https://docs.opencv.org/master/dc/dc3/tutorial_py_matcher.html
draw_params = dict(matchColor=(0, 255, 0),
                   singlePointColor=(255, 0, 0),
                   matchesMask=matchesMask[300:500],
                   flags=cv2.DrawMatchesFlags_DEFAULT)

keypoint_matches = cv2.drawMatchesKnn(
    left_img, kp1, right_img, kp2, matches[300:500], None, **draw_params)

# cv2.imshow("Keypoint matches", keypoint_matches)
# cv2.waitKey(0)
# cv2.destroyAllWindows()

# ------------------------------------------------
# Calculate the fundamental matrix for the cameras
# ------------------------------------------------
# https://docs.opencv.org/master/da/de9/tutorial_py_epipolar_geometry.html
pts1 = np.int32(pts1)
pts2 = np.int32(pts2)
fundamental_matrix, inliers = cv2.findFundamentalMat(pts1, pts2, cv2.FM_RANSAC)

# We select only inlier points
pts1 = pts1[inliers.ravel() == 1]
pts2 = pts2[inliers.ravel() == 1]

# ------------------
# Visualize epilines
# ------------------
# Adapted from: https://docs.opencv.org/master/da/de9/tutorial_py_epipolar_geometry.html
def drawlines(img1src, img2src, lines, pts1src, pts2src):
    ''' img1 - image on which we draw the epilines for the points in img2
        lines - corresponding epilines '''
    r, c = img1src.shape
    img1color = cv2.cvtColor(img1src, cv2.COLOR_GRAY2BGR)
    img2color = cv2.cvtColor(img2src, cv2.COLOR_GRAY2BGR)
    # Edit: use the same random seed so that two images are comparable!
    np.random.seed(0)
    for r, pt1, pt2 in zip(lines, pts1src, pts2src):
        color = tuple(np.random.randint(0, 255, 3).tolist())
        x0, y0 = map(int, [0, -r[2]/r[1]])
        x1, y1 = map(int, [c, -(r[2]+r[0]*c)/r[1]])
        img1color = cv2.line(img1color, (x0, y0), (x1, y1), color, 1)
        img1color = cv2.circle(img1color, tuple(pt1), 5, color, -1)
        img2color = cv2.circle(img2color, tuple(pt2), 5, color, -1)
    return img1color, img2color


# Find epilines corresponding to points in right image (second image) and
# drawing its lines on left image
lines1 = cv2.computeCorrespondEpilines(
    pts2.reshape(-1, 1, 2), 2, fundamental_matrix)
lines1 = lines1.reshape(-1, 3)
img5, img6 = drawlines(left_img, right_img, lines1, pts1, pts2)

# Find epilines corresponding to points in left image (first image) and
# drawing its lines on right image
lines2 = cv2.computeCorrespondEpilines(
    pts1.reshape(-1, 1, 2), 1, fundamental_matrix)
lines2 = lines2.reshape(-1, 3)
img3, img4 = drawlines(right_img, left_img, lines2, pts2, pts1)

# DEBUG: Epilines
# plt.subplot(121), plt.imshow(img5)
# plt.subplot(122), plt.imshow(img3)
# plt.suptitle("Epilines in both images")
# plt.show()

# Stereo rectification (uncalibrated variant)
# Adapted from: https://stackoverflow.com/a/62607343
h1, w1 = left_img.shape
h2, w2 = right_img.shape
_, H1, H2 = cv2.stereoRectifyUncalibrated(
    np.float32(pts1), np.float32(pts2), fundamental_matrix, imgSize=(w1, h1)
)

print('left, h1')
print(h1)
print('left, w1')
print(w1)
print('left, H1')
print(H1)
print('right, H2')
print(H2)

# --------------------------------------------
# Undistort (rectify) the images and save them
# --------------------------------------------
# Adapted from: https://stackoverflow.com/a/62607343
img1_rectified = cv2.warpPerspective(left_img, H1, (w1, h1))
img2_rectified = cv2.warpPerspective(right_img, H2, (w2, h2))
cv2.imwrite("/Users/brianli/Desktop/stereo_test_images/rectified_left.png", img1_rectified)
cv2.imwrite("/Users/brianli/Desktop/stereo_test_images/rectified_right.png", img2_rectified)

# Draw the rectified images
fig, axes = plt.subplots(1, 2, figsize=(15, 10))
axes[0].imshow(img1_rectified, cmap="gray")
axes[1].imshow(img2_rectified, cmap="gray")
axes[0].axhline(250)
axes[1].axhline(250)
axes[0].axhline(450)
axes[1].axhline(450)
# plt.suptitle("Rectified images")
# plt.savefig("/Users/brianli/Desktop/stereo_test_images/rectified_images.png")
# # plt.show()


# ------------------------------------------------------------
# CALCULATE DISPARITY (DEPTH MAP)
# Adapted from: https://github.com/opencv/opencv/blob/master/samples/python/stereo_match.py
# and: https://docs.opencv.org/master/dd/d53/tutorial_py_depthmap.html

# StereoSGBM Parameter explanations:
# https://docs.opencv.org/4.5.0/d2/d85/classcv_1_1StereoSGBM.html

# Matched block size. It must be an odd number >=1 . Normally, it should be somewhere in the 3..11 range.
block_size = 11
min_disp = -128
max_disp = 128
# Maximum disparity minus minimum disparity. The value is always greater than zero.
# In the current implementation, this parameter must be divisible by 16.
num_disp = max_disp - min_disp
# Margin in percentage by which the best (minimum) computed cost function value should "win" the second best value to consider the found match correct.
# Normally, a value within the 5-15 range is good enough
uniquenessRatio = 10
# Maximum size of smooth disparity regions to consider their noise speckles and invalidate.
# Set it to 0 to disable speckle filtering. Otherwise, set it somewhere in the 50-200 range.
speckleWindowSize = 200
# Maximum disparity variation within each connected component.
# If you do speckle filtering, set the parameter to a positive value, it will be implicitly multiplied by 16.
# Normally, 1 or 2 is good enough.
speckleRange = 2
disp12MaxDiff = 0

stereo = cv2.StereoSGBM_create(
    minDisparity=min_disp,
    numDisparities=num_disp,
    blockSize=block_size,
    uniquenessRatio=uniquenessRatio,
    speckleWindowSize=speckleWindowSize,
    speckleRange=speckleRange,
    disp12MaxDiff=disp12MaxDiff,
    P1=8 * 1 * block_size * block_size,
    P2=32 * 1 * block_size * block_size,
)
disparity_SGBM = stereo.compute(img1_rectified, img2_rectified)

# Normalize the values to a range from 0..255 for a grayscale image
disparity_SGBM = cv2.normalize(disparity_SGBM, disparity_SGBM, alpha=255,
                              beta=0, norm_type=cv2.NORM_MINMAX)
disparity_SGBM = np.uint8(disparity_SGBM)
# cv2.imshow("Disparity", disparity_SGBM)
# cv2.imwrite("/Users/brianli/Desktop/stereo_test_images/disparity_SGBM_norm.png", disparity_SGBM)
# plt.imshow(disparity_SGBM, cmap='plasma')
# plt.colorbar()
# plt.show()

"""

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
    block_width = block_size//2
    left_row, left_col = left_pixel
    right_row, right_col = right_pixel

    left_subset = left_rectified[left_row-block_width:left_row+block_width+1, left_col-block_width:left_col+block_width+1]
    right_subset = right_rectified[right_row-block_width:right_row+block_width+1, right_col-block_width:right_col+block_width+1]

    
    return np.sum(np.abs(left_subset-right_subset)**2)

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
    block_width = block_size//2

    print('image dim', left_rectified.shape)
    for r in range(block_width, num_rows-block_width):
        print('row', r)
        # if r == 40:
        #     break
        for c in range(block_width, num_cols-block_width):
            temp_disparities = [] # for debug
            min_sofar = float('inf')
            min_offset = 0
            # for offset in range(block_width, num_cols-block_width):
            for offset in range(max_offset):
                # print("offset", offset)
                # print("(r, c): ({}, {})".format(r, c))
                if c - offset > block_width:
                    left_pixel = (r, c)
                    right_pixel = (r, c-offset)
                    # print('left pixel', left_pixel)
                    # print('right_pixel', right_pixel)
                    result = compute_sad(left_rectified, right_rectified, left_pixel, right_pixel, block_size)
                    if result < min_sofar:
                        min_sofar = result
                        min_offset = offset
            disparity_map[r,c] = min_offset
    return disparity_map

# img1_rectified_downscaled = cv2.resize(img1_rectified, (320, 240))
# img2_rectified_downscaled = cv2.resize(img2_rectified, (320, 240))

# img1_rectified_downscaled = cv2.resize(left_img,  (320, 240))
# img2_rectified_downscaled = cv2.resize(right_img, (320, 240))
img1_rectified_downscaled = left_img
img2_rectified_downscaled = right_img
max_offset = 30
block_size = 6
disparity_map = sad_disparity(img1_rectified_downscaled , img2_rectified_downscaled, block_size=block_size, max_offset=max_offset)
# dispairty_map = cv2.normalize(disparity_map, None, 0, 255, cv2.NORM_MINMAX)
print(disparity_map.shape)
disparity_map = disparity_map * (255/max_offset)
print(list(disparity_map))

print(left_img.shape)
print(right_img.shape)
# cv2.imshow("Disparity", disparity_map)
# cv2.imwrite("/Users/brianli/Desktop/stereo_test_images/disparity_sad_image_1.png", disparity_map)

plt.imshow(disparity_map, cmap='plasma')
plt.title("Block Size = {}, Max Offset = {}".format(block_size, max_offset))
plt.colorbar()
plt.show()