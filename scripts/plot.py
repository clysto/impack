import seaborn as sns
import matplotlib.pyplot as plt
import pandas as pd

if __name__ == "__main__":
    results = pd.read_csv("scripts/results.csv")

    plt.figure()
    sns.violinplot(data=results, x="QUALITY", y="CR", fill=False)
    plt.show(block=False)

    plt.figure()
    sns.violinplot(data=results, x="QUALITY", y="PSNR", fill=False)
    plt.show(block=False)

    plt.figure()
    sns.barplot(data=results, x="QUALITY", y="ENCODE_TIME")
    plt.show(block=False)

    plt.figure()
    sns.barplot(data=results, x="QUALITY", y="DECODE_TIME")
    plt.show(block=False)

    plt.figure()
    sns.barplot(data=results[results["QUALITY"] == "poor"], x="ID", y="CR")
    plt.show()
