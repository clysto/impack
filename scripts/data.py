import sys

import matplotlib.pyplot as plt
import numpy as np
from PIL import Image
from utils import block_slice

im = Image.open(sys.argv[1])
im = im.convert("L")
im = np.array(im)

plt.figure()
plt.imshow(im, cmap="gray")
plt.show()

im = block_slice(im, (8, 8))
im = im.reshape(-1, 8, 8)

im.tofile("a.dat")
