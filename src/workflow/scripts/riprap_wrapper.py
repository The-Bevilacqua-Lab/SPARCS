################################################################################
# Wrapper for RipRap prediction tool
#
# Author: Kobie Kirven
#
# Assmann and Bevilacqua Labs
# The Pennsylvania State University
################################################################################

# Imports
import argparse
import numpy as np
import subprocess
import tempfile
import os
import string
import random

# Get the location of this file:
location = os.getcwd()

# Get the path up to the SPARCS directory:
path = []
for ele in location.split("/"):
    if ele == "SPARCS":
        path.append(ele)
        break
    else:
        path.append(ele)

# Convert the path to a string:
path = "/".join(path)


def make_temp_riprap_input(sequence, mutation):
    """
    Create a temporary input file for RipRap. 
    We will use random integers and letters to name the sequence.
    """
    fn = tempfile.NamedTemporaryFile(delete=False)
    name = "".join(
        random.choice(string.ascii_uppercase + string.digits) for _ in range(6)
    )

    fn.write(('{0}\t{1}\t{2}\n'.format(name, sequence, mutation).encode("utf-8")))
    return fn.name, name

def run_riprap(sequence, mutation, path, temp, minwindow, tool, win_type):
    """
    Run RipRap on the sequence.
    """
    # Make the input file:
    fn, name = make_temp_riprap_input(sequence, mutation)
    name = "".join(
        random.choice(string.ascii_uppercase + string.digits) for _ in range(6)
    )

    # Run RipRap:
    riprap = subprocess.call(["python2", "{0}/workflow/scripts/riprap.py".format(path), "--i", fn, "--o", name, "--foldtype", str(tool), "-T", str(temp), "-w", str(minwindow), "-f", str(win_type)], stdout=subprocess.PIPE, stderr=subprocess.PIPE)

    # Check for errors:
    if riprap.stderr != None:
        return "NA"

    # Read the output:
    with open("{0}_riprap_score.tab".format(name)) as f:
        lines = f.readlines()

    # Remove the temporary file:
    os.remove("{0}_riprap_score.tab".format(name))

    # Return the score:
    try:
        score = lines[1].split(",")[1]
        return score
    except:
        return "NA"

# Parse the arguments:
parser = argparse.ArgumentParser(description="Determine RiboSNitches")
parser.add_argument("--i", dest="in_file", help="Input File")
parser.add_argument("--o", dest="output", help="Output")
parser.add_argument("--flank", dest="flank", help="Flanking length")
parser.add_argument("--temp", dest="temp", help="Temperature", default=37.0)
parser.add_argument("--minwindow", dest="minwindow", help="Minimum Window", default=3)
parser.add_argument("--windowtype", dest="windowtype", help="Window Type", default=0)
parser.add_argument("--tool", dest="tool", help="Tool", default="RNAfold")
args = parser.parse_args()

# Open the input file
fn = open(args.in_file)
lines = fn.readlines()

# Open the output files and the error 
out = open(args.output, "w")
error = open(args.output[:-4] + "_error.txt", "w")

# Loop through the input file and perform the riboSNitch prediction:
for line in lines:
    # Skip the header:
    if not line.startswith("#"):
        line = line.split("\t")

        # Make sure we don't have any indels:
        if not len(line[3]) == 1 or not len(line[4]) == 1:
            continue

        # Change the reference and alternative alleles
        if line[3] == "T":
            line[3] = "U"
        if line[4] == "T":
            line[4] = "U"

        # Get the mutation 
        seq = str(line[5]) + str(line[3]) + str(line[6])
        mutation = "{0}{1}{2}".format(str(line[3]),str(int(args.flank) + 1), str(line[4]))

        # Get the tool number:
        if args.tool == "RNAfold":
            number = 1
        if args.tool == "RNAstructure":
            number = 2

        # Run RipRap:
        score = run_riprap(seq, mutation, path, args.temp, args.minwindow, number, args.windowtype)

        # Write the output:
        if score == "NA":
            error.write("\t".join(line) + "\n")
        else:
            out.write("\t".join(line).strip("\n") + "\t" + str(score)+ "\n")

