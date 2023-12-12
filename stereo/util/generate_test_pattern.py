import plotly.graph_objs as go
from plotly.subplots import make_subplots

import cv2
import numpy as np
import matplotlib.pyplot as plt
from PIL import Image

def generate_test_image(num_rows=320, num_cols=240, pattern=[100,100,100,100,100,100,0,0,0,0,0,0], fp=""):
	test_image = []
	for row in range(num_rows):
		temp_row = []
		for i in range(20):
			temp_row += pattern
		test_image.append(temp_row)
	
	test_image = np.array(test_image)
	print(test_image)
	print("Generated test image of size:", test_image.shape)
	image = Image.fromarray(test_image.astype(np.uint8))
	image.save(fp)

fp = '/Users/brianli/Desktop/6.111/stereo_test_images/LEFT_TEST_PATTERN.png'
generate_test_image(num_rows=320, num_cols=240, pattern=[100,100,100,100,100,100,0,0,0,0,0,0], fp=fp)

fp = '/Users/brianli/Desktop/6.111/stereo_test_images/RIGHT_TEST_PATTERN.png'
generate_test_image(num_rows=320, num_cols=240, pattern=[0,0,0,0,0,0,100,100,100,100,100,100], fp=fp)


