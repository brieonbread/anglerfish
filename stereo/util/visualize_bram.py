import plotly.graph_objs as go
from plotly.subplots import make_subplots

import cv2
import numpy as np
import matplotlib.pyplot as plt

# --------------
# Read in images
# --------------
left_fp = "/Users/brianli/Desktop/stereo_test_images/bowling_left.png"
right_fp = "/Users/brianli/Desktop/stereo_test_images/bowling_right.png"
left_img = cv2.imread(left_fp, 0)

right_img = cv2.imread(right_fp, 0)

print(left_img.shape)

# Create a sample 2D array (replace this with your data)
data = [
    [1, 2, 3, 4, 5],
    [6, 7, 8, 9, 10],
    [11, 12, 13, 14, 15],
    [16, 17, 18, 19, 20]
]

data = left_img
# Get array dimensions
rows, cols = len(data), len(data[0])

# Create meshgrid for x and y coordinates
x_vals = list(range(cols))
y_vals = list(range(rows))

# Create trace for heatmap
heatmap_trace = go.Heatmap(
    x=x_vals,
    y=y_vals,
    z=data,
    hoverinfo="z",  # Display only the z value on hover
    colorscale="Viridis",  # You can change the color scale
)

# Create subplot
fig = make_subplots()

# Add heatmap trace to the subplot
fig.add_trace(heatmap_trace)

# Update layout
fig.update_layout(
    title_text="2D Array with Hover Values",
    xaxis=dict(title="X Axis"),
    yaxis=dict(title="Y Axis"),
)

# Show the plot
fig.show()