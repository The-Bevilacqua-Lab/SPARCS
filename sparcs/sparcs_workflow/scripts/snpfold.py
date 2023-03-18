##################################################################
# This script will calculate the SNPfold score for a given SNP
#
# Original code was obtained from https://github.com/Halvee/SNPfold
# Updated for python3 by Kobie Kirven
# Assmann and Bevilacqua Labs
##################################################################

# Imports
import argparse
import numpy as np
import subprocess
import tempfile
import os
import string
import random


parser = argparse.ArgumentParser(description="Calculate SNPfold score for a given SNP")
parser.add_argument("-seq", dest="seq", help="Sequence")
parser.add_argument("-mut", dest="mutation", help="Mutation")
parser.add_argument("-T", dest="temp", help="Temperature")
args = parser.parse_args()

# Check to make sure "N" is not in the sequence
if "N" in args.seq:
    raise ValueError("N is in the sequence")

# Check to make sure "N" is not in the mutation
if "N" in args.mutation:
    raise ValueError("N is in the mutation")


def get_temp_fasta(sequence):
    """
    Writes a temporary fasta file with the given sequence
    """
    fn = tempfile.NamedTemporaryFile(delete=False)
    name = "".join(
        random.choice(string.ascii_uppercase + string.digits) for _ in range(6)
    )
    fn.write(b">.sq" + name.encode("utf-8") + b"\n")
    fn.write(sequence.encode("utf-8"))
    return fn.name, name


def get_bppm(sequence):
    """
    Runs RNAfold on the given sequence and returns the base pair probibility matrix
    """
    temp_fasta, name = get_temp_fasta(sequence)
    bpp = subprocess.check_output(
        ["RNAfold", "-p", "--noPS", "-i", temp_fasta, "-T", args.temp]
    ).decode("utf-8")
    bpp_matrix = np.zeros((len(sequence), len(sequence)), dtype=float)

    with open(".sq" + name + "_dp.ps") as fn:
        lines = fn.readlines()
        for line in lines:
            if "ubox\n" in line:
                line = line.split(" ")
                if len(line) == 4:
                    if line[3] == "ubox\n":
                        bpp_matrix[int(line[0]) - 1, int(line[1]) - 1] = float(
                            line[2]
                        ) * float(line[2])
                        bpp_matrix[int(line[1]) - 1, int(line[0]) - 1] = float(
                            line[2]
                        ) * float(line[2])
    os.remove(temp_fasta)
    try:
        os.remove(".sq" + name + "_dp.ps")
    except:
        pass
    return bpp_matrix


def get_sum_matrix_cols(bpp_matrix):
    "Get the column sums from a BPP matrix"
    return np.sum(bpp_matrix, axis=0)


def get_pearson(list1, list2):
    """
    Calculate the Pearson correlation coefficient between two lists
    """
    return np.corrcoef(list1, list2)[0][1]


if __name__ == "__main__":
    # Get the BPP matrices
    bpp_matrix = get_bppm(args.seq)
    bpp_matrix_mut = get_bppm(
        args.seq[: int(args.mutation[1:-1]) - 1]
        + args.mutation[-1]
        + args.seq[int(args.mutation[1:-1]) :]
    )

    # Get the column sums
    col_sums = get_sum_matrix_cols(bpp_matrix)
    col_sums_mut = get_sum_matrix_cols(bpp_matrix_mut)

    # Calculate the Pearson correlation coefficient
    pearson = get_pearson(col_sums, col_sums_mut)
    print(pearson)
