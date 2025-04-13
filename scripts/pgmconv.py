#!/usr/bin/env python

import argparse
from PIL import Image


def save_pgm(image: Image.Image, fp, raw: bool):
    width, height = image.size
    pixels = image.convert("L").tobytes()
    if raw:
        fp.write(f"P5\n{width} {height}\n255\n".encode("ascii"))
        fp.write(pixels)
    else:
        fp.write(f"P2\n{width} {height}\n255\n".encode("ascii"))
        for i, val in enumerate(pixels):
            fp.write(f"{val} ".encode("ascii"))
            if (i + 1) % width == 0:
                fp.write(b"\n")


if __name__ == "__main__":
    arg = argparse.ArgumentParser(description="Convert Images to PGM format.")
    arg.add_argument("input", help="Input image file (any format supported by Pillow)")
    arg.add_argument("output", help="Output PGM file")
    arg.add_argument("--raw", action="store_true", help="Use binary PGM format (P5)")
    args = arg.parse_args()

    image = Image.open(args.input)
    with open(args.output, "wb") as f:
        save_pgm(image, f, args.raw)
