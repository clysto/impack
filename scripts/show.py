import sys

import matplotlib.pyplot as plt
import numpy as np
from utils import block_combine

dat = np.fromfile(sys.argv[1], dtype=np.uint8)
dat = dat.reshape(64, 64, 8, 8)
im = block_combine(dat)
im = im.reshape(512, 512)

plt.figure()
plt.imshow(im, cmap="gray")
plt.show()
