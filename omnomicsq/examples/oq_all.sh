#!/bin/bash 
#
# Example of how to script the omnomicsQ command line client.
#
# Usage: ./oq_all.sh /path/to/run/directory
#
# The run directory should be a directory containing the data from an Illumina
# sequencing run (the directory is expected to contain files named `RunInfo.xml`
# and `SampleSheet.csv` among others)

### -- BEGIN SETTINGS --- ###
# Customize your settings here.

# client_dir: Set this directory to point to the directory where the
# `omnomicsq_cli` command line application resides.
client_dir="/opt/omnomicsq-cli"

# device: Set this to the ID of your sequencing device
device=1

# sop: Set this to the ID of your QC protocol
sop=6

# bed: Set this to point to your BED file
bed="/path/to/your/bed/file"

### --- END SETTINGS --- ###

run_dir="$1"

# 1. Illumina run metrics

${client_dir}/omnomicsq_cli illumina_run_metrics --device="${device}" "${run_dir}"

# 2.1. Raw QC metrics from fastq files

# We obtain the list of sample ids from the `[Data]`section of the file
# `SampleSheet.csv` in the run directory
sed -n '/^\[Data\]/,$p' "$run_dir/SampleSheet.csv" | tail -n +3 | 
while IFS=',' read -r sample_id rest
do
    sample_key="${sample_id}_S1"
    files="${run_dir}/Data/Intensities/BaseCalls/${sample_key}*.fastq.gz"
    echo "Raw QC: ${sample_key}: ${files}"
    ${client_dir}/omnomicsq_cli raw --device="${device}" --sop="${sop}" --sample="${sample_key}" ${files}
done

# 2.2. Aligned QC metrics from BAM files

sed -n '/^\[Data\]/,$p' "${run_dir}/SampleSheet.csv" | tail -n +3 |
while IFS=',' read -r sample_id rest
do
    sample_key="${sample_id}_S1"
    file="${run_dir}/Data/Intensities/BaseCalls/Alignments/${sample_key}.bam"
    echo "Aligned QC: ${sample_key}: ${file}"
    ${client_dir}/omnomicsq_cli aligned --device="${device}" --sop="${sop}" --bed="${bed}" --sample="${sample_key}" ${file}
done

# 2.3. Variant call QC metrics from VCF files

sed -n '/^\[Data\]/,$p' "${run_dir}/SampleSheet.csv" | tail -n +3 | 
while IFS=',' read -r sample_id rest
do
    sample_key="${sample_id}_S1"
    file="${run_dir}/Data/Intensities/BaseCalls/Alignments/Variants/${sample_key}.vcf"
    echo "VCF QC: ${sample_key}: ${file}"
    ${client_dir}/omnomicsq_cli vcf --device="${device}" --sop="${sop}" --sample="${sample_key}" ${file}
done
