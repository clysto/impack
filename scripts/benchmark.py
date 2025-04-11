import sys
import time
from pathlib import Path
from subprocess import PIPE, Popen

import numpy as np
from PIL import Image
from utils import block_combine, block_slice


def psnr(im1, im2):
    mse = np.mean((im1 - im2) ** 2)
    return 10 * np.log10(255**2 / mse)


if __name__ == "__main__":
    print("ID,QUALITY,PSNR,CR,ENCODE_TIME,DECODE_TIME")
    for quality in ["poor", "low", "medium", "high", "best"]:
        for i in range(1, 40):
            im = Image.open(Path(__file__).parent / "images" / f"{i}.gif")
            im = im.convert("L")
            im = np.array(im)
            im_o = im.copy()
            im = block_slice(im, (8, 8))
            im = im.reshape(-1, 8, 8)
            process = Popen([sys.argv[1], "encode", "512", "512", quality], stdin=PIPE, stdout=PIPE)

            start = time.time()
            out = process.communicate(input=im.tobytes())[0]
            end = time.time()

            encode_time = end - start
            cr = 512 * 512 / len(out)
            process = Popen([sys.argv[1], "decode"], stdin=PIPE, stdout=PIPE)

            start = time.time()
            out = process.communicate(input=out)[0]
            end = time.time()
            decode_time = end - start

            out = np.frombuffer(out, dtype=np.uint8)
            out = out.reshape(64, 64, 8, 8)
            im_r = block_combine(out)
            snr = psnr(im_o, im_r)
            print(f"{i},{quality},{snr},{cr},{encode_time},{decode_time}")
