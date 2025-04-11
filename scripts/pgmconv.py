#!/usr/bin/env python

import argparse
from PIL import Image


def save_pgm(image: Image.Image, path: str, raw: bool):
    width, height = image.size
    pixels = image.convert("L").tobytes()
    with open(path, "wb") as f:
        if raw:
            f.write(f"P5\n{width} {height}\n255\n".encode("ascii"))
            f.write(pixels)
        else:
            f.write(f"P2\n{width} {height}\n255\n".encode("ascii"))
            for i, val in enumerate(pixels):
                f.write(f"{val} ".encode("ascii"))
                if (i + 1) % width == 0:
                    f.write(b"\n")


if __name__ == "__main__":
    arg = argparse.ArgumentParser(description="Convert Images to PGM format.")
    arg.add_argument("input", help="Input image file (any format supported by Pillow)")
    arg.add_argument("output", help="Output PGM file")
    arg.add_argument("--raw", action="store_true", help="Use binary PGM format (P5)")
    args = arg.parse_args()

    image = Image.open(args.input)
    save_pgm(image, args.output, args.raw)
