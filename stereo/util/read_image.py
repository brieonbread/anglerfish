import plotly.graph_objs as go
from plotly.subplots import make_subplots

import cv2
import numpy as np
import matplotlib.pyplot as plt
from PIL import Image


disparity_fp = "/Users/brianli/Desktop/6.111/anglerfish/stereo/data/disparity_debug.jpg"


# read in left/right image files
disparity_img = cv2.imread(disparity_fp, 0)

plt.imshow(disparity_img, cmap='gray')
plt.title("Debug Image")
plt.colorbar()
plt.show()
