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
plt.show(block=False)

if len(sys.argv) > 2:
    dat2 = np.fromfile(sys.argv[2], dtype=np.uint8)
    dat2 = dat2.reshape(64, 64, 8, 8)
    im2 = block_combine(dat2)
    im2 = im2.reshape(512, 512)
    plt.figure()
    plt.imshow(im2, cmap="gray")
    plt.show(block=False)

    plt.figure()
    plt.imshow(np.log10(np.abs(im.astype(np.int32) - im2.astype(np.int32)) + 1))
    plt.colorbar()
    plt.show(block=False)

plt.show()
