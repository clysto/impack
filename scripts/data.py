import numpy as np
from PIL import Image
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


im = Image.open("images/1.gif")
im = im.convert("L")
im = im.resize((256, 256))
im = np.array(im)

plt.figure()
plt.imshow(im, cmap="gray")
plt.show()

im = block_slice(im, (8, 8))
im = im.reshape(-1, 8, 8)

im.tofile("lenna.dat")
