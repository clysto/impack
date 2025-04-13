import sys
import io
import time
from pathlib import Path
from subprocess import PIPE, Popen
from pgmconv import save_pgm

import numpy as np
from PIL import Image


def psnr(im1, im2):
    mse = np.mean((im1 - im2) ** 2)
    return 10 * np.log10(255**2 / mse)


if __name__ == "__main__":
    print("ID,QUALITY,PSNR,CR,ENCODE_TIME,DECODE_TIME")
    for quality in ["poor", "low", "medium", "high", "best"]:
        for i in range(1, 40):
            im = Image.open(Path(__file__).parent / "images" / f"{i}.gif")
            im = im.convert("L")
            buf = io.BytesIO()
            save_pgm(im, buf, raw=True)

            process = Popen([sys.argv[1], "encode", quality], stdin=PIPE, stdout=PIPE)

            start = time.time()
            out = process.communicate(input=buf.getvalue())[0]
            end = time.time()

            encode_time = end - start
            cr = 512 * 512 / len(out)
            process = Popen([sys.argv[1], "decode"], stdin=PIPE, stdout=PIPE)

            start = time.time()
            out = process.communicate(input=out)[0]
            end = time.time()

            decode_time = end - start
            im_recover = Image.open(io.BytesIO(out))

            snr = psnr(np.array(im), np.array(im_recover))
            print(f"{i},{quality},{snr},{cr},{encode_time},{decode_time}")
