import matplotlib.pyplot as plt
import numpy as np
from utils import block_combine

dat = np.fromfile("b.dat", dtype=np.uint8)
dat = dat.reshape(64, 64, 8, 8)
lenna = block_combine(dat)
lenna = lenna.reshape(512, 512)

plt.figure()
plt.imshow(lenna, cmap="gray")
plt.show()
