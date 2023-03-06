############################################################################################
# Rules for running the Riprap tool
#
# Author: Kobie Kirven
# Assmann and Bevilacqua Labs
# The Pennsylvania State University
############################################################################################

# Path to the config file 
configfile: srcdir("../config.yaml")


# Import the python modules:
import os

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


###########################
# Rules for running Riprap
###########################
rule run_riprap:
    # Perform the riboSNitch analysis with Riprap
    input:
        f"{config['working_directory']}/{config['out_name']}/temp/extracted_seqs_chunks/extracted_flank_snp_{{i}}.txt"
    params:
        f"{{temp_deg}}",
    output:
        ribo=f"{config['working_directory']}/{config['out_name']}/temp/ribosnitch_chunks_{{temp_deg}}/chunk_{{i}}_riboSNitch_{{temp_deg}}.txt",
        error=f"{config['working_directory']}/{config['out_name']}/temp/ribosnitch_chunks_{{temp_deg}}/chunk_{{i}}_riboSNitch_{{temp_deg}}_error.txt",
    conda:
        "../envs/riprap.yaml"
    log:
        f"{config['working_directory']}/{config['out_name']}/logs/ribosnitch_prediction/chunk_{{i}}_riboSNitch_{{temp_deg}}.log",
    shell:
        f"python3 {path}/workflow/scripts/riprap_wrapper.py --i {{input[0]}} --o {{output.ribo}} --flank {config['flank_len']} --temp {{params}}"


rule combine_ribosnitch_results:
    # Combine the results of riboSNitch prediction into one file
    input:
        [
            f"{config['working_directory']}/{config['out_name']}/temp/ribosnitch_chunks_{{temp_deg}}/chunk_{i}_riboSNitch_{{temp_deg}}.txt"
            for i in range(1, config["chunks"] + 1)
        ],
    output:
        f"{config['working_directory']}/{config['out_name']}/results/ribosnitch_predictions/combined_ribosnitch_prediction_{{temp_deg}}.txt",
    log:
        f"{config['working_directory']}/{config['out_name']}/logs/combine_ribosnitch_results_{{temp_deg}}.log",
    shell:
        "cat {input} > {output}"