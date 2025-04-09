import numpy as np
import matplotlib.pyplot as plt


def block_slice(image: np.ndarray, kernel_size: tuple):
    img_height, img_width = image.shape
    tile_height, tile_width = kernel_size
    tiled_array = image.reshape(img_height // tile_height, tile_height, img_width // tile_width, tile_width)
    tiled_array = tiled_array.swapaxes(1, 2)
    return tiled_array


def block_combine(tiled_array: np.ndarray):
    h, w, tile_height, tile_width = tiled_array.shape
    height = h * tile_height
    width = w * tile_width
    tiled_array = tiled_array.swapaxes(1, 2)
    image = tiled_array.reshape(height, width)
    return image


dat = np.fromfile("b.dat", dtype=np.uint8)
dat = dat.reshape(32, 32, 8, 8)
lenna = block_combine(dat)
lenna = lenna.reshape(256, 256)

plt.figure()
plt.imshow(lenna, cmap="gray")
plt.show()
