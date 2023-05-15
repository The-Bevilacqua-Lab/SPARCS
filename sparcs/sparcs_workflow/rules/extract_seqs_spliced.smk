################################################################################
# Rules for extracting sequences from the reference genome
#
# Author: Kobie Kirven
#
# Assmann and Bevilacqua Labs
# The Pennsylvania State University
################################################################################


# Read in the config file:
configfile: srcdir("../config.yaml")


# Import the python modules:
import os


if config['scramble'] == True:
    combine_input = expand(f"{config['working_directory']}/{config['out_name']}/temp/extracted_sequences/shuffled_seqs_{{i}}.txt",
        i=range(1, config["chunks"] + 1),
    ),
else:
    combine_input = expand(
        f"{config['working_directory']}/{config['out_name']}/temp/extracted_sequences/extracted_seqs_{{i}}.txt",
        i=range(1, config["chunks"] + 1),
    ),

rule create_gffutils:
    # Create the gffutils database
    params:
        gtf=config["gtf_file"],
    output:
        f"{config['working_directory']}/{config['out_name']}/temp/{config['gtf_file'].split('/')[-1].strip('.gtf')}.db",
    singularity:
        "docker://kjkirven/process_seq"
    shell:
        f"python3 scripts/build_gffutils.py --gtf {{params.gtf}} --o {{output}}"

rule extract_cdna_from_gff_with_gffread:
    # Extract the cDNA sequences from the GTF file
    params:
        gtf=config["gtf_file"],
        ref=config["ref_genome"],
    output:
        f"{config['working_directory']}/{config['out_name']}/temp/cdna.fa",
    # singularity:
    #     "docker://kjkirven/process_seq"
    shell:
        f"gffread {{params.gtf}} -g {{params.ref}} -w {{output}}"

rule get_cds_start:
    input:
        f"{config['working_directory']}/{config['out_name']}/temp/cdna.fa",
    output:
        f"{config['working_directory']}/{config['out_name']}/temp/cdna_pos.txt",
    shell:
        "cat {input} | grep '>' > {output}"


rule extract_sequences:
    # Extract the sequences flanking the SNP
    input:
        vcf=f"{config['working_directory']}/{config['out_name']}/temp/annotated_vcf_chunks_effects/vcf_no_header_{{i}}_annotated_one_per_line.txt",
        database=f"{config['working_directory']}/{config['out_name']}/temp/{config['gtf_file'].split('/')[-1].strip('.gtf')}.db",
        cds_pos=f"{config['working_directory']}/{config['out_name']}/temp/cdna_pos.txt",
        cdna = f"{config['working_directory']}/{config['out_name']}/temp/cdna.fa"
    params:
        flank=config["flank_len"],
    output:
        seqs=f"{config['working_directory']}/{config['out_name']}/temp/extracted_sequences/extracted_seqs_{{i}}.txt",
    # singularity:
    #     "docker://kjkirven/process_seq"
    # conda:
    #     "../envs/process_seq.yaml"
    shell:
        f"python3 scripts/get_spliced_read_data.py --vcf {{input.vcf}} --database {{input.database}} --ref-seqs {{input.cdna}} --flank {{params.flank}} --cds-pos {{input.cds_pos}} --o {{output.seqs}}"

rule combine_extracted_sequences:
    # Combine the extracted sequences into one file
    input:
        combine_input
    output:
        f"{config['working_directory']}/{config['out_name']}/temp/extracted_flank_snp.txt",
    shell:
        "cat {input} > {output}"

rule remove_duplicates:
    # Remove duplicates from the extracted sequences
    input:
        f"{config['working_directory']}/{config['out_name']}/temp/extracted_flank_snp.txt",
    output:
        f"{config['working_directory']}/{config['out_name']}/temp/extracted_flank_snp_no_duplicates.txt",
    singularity:
        "docker://kjkirven/process_seq"
    shell:
        f"python3 scripts/remove_duplicates.py -i {{input}} -o {{output}}"