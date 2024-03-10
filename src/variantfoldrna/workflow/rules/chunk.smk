################################################################################
# Rules for breaking up files into smaller, more managable chunks
#
# Author: Kobie Kirven
#
# Assmann and Bevilacqua Labs
# The Pennsylvania State University
################################################################################


import os 
import sys

# Get the path to the script
script_path = os.path.realpath(__file__)
src_dir = os.path.dirname(script_path)

rule chunk_vcf:
    # Break up the VCF file in to bite-sized chunks so that it is easier to process
    input:
        vcf=f"{config['tmp_dir']}/temp/vcf_no_header.vcf.gz",
        header=f"{config['tmp_dir']}/temp/vcf_header.txt.gz",
    output:
        expand(
            f"{config['tmp_dir']}/temp/vcf_chunks/vcf_no_header_{{i}}.vcf.gz",
            i=range(1, int(config["chunks"]) + 1),
        ),
    conda:
        "../envs/process_seq.yaml"
    singularity:
        "docker://condaforge/mambaforge"
    log:
        f"{config['tmp_dir']}/logs/chunk_vcf.log",
    shell:
        f"python3 {src_dir}/../variantfoldrna/workflow/scripts/chunk_vcf.py --input {{input.vcf}} --dir {config['tmp_dir']}/temp --vcf-header {{input.header}} --chunk-total {config['chunks']} > {{log}}"


rule chunk_extracted_sequences:
    # Chunk the extracted sequences:
    input:
        f"{config['tmp_dir']}/temp/extracted_flank_snp_no_duplicates.txt",
    output:
        expand(
            f"{config['tmp_dir']}/temp/extracted_seqs_chunks/extracted_flank_snp_{{i}}.txt",
            i=range(1, config["chunks"] + 1),
        ),
    conda:
        "../envs/process_seq.yaml"
    singularity:
        "docker://condaforge/mambaforge"
    shell:
        f"python3 {src_dir}/../variantfoldrna/workflow/scripts/chunk_extracted_seqs.py --input {{input}} --dir {config['tmp_dir']}/temp --chunk-total {config['chunks']}"
