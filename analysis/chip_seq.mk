#
# This is a simple Makefile to download and process ChIP-seq data
#

# Variables
# ref genome
URL ?= http://hgdownload.cse.ucsc.edu/goldenPath/sacCer3/bigZips/chromFa.tar.gz
# Chromosome sizes
CHROM_SIZES_URL ?= http://hgdownload.cse.ucsc.edu/goldenPath/sacCer3/bigZips/sacCer3.chrom.sizes
# Reference genome location
REF ?= refs/saccer3.fa
# Chromosome sizes location
CHROM_SIZES ?= refs/sacCer3.chrom.sizes
# The design file
DESIGN ?= design.csv
# flags to pass to parallel
FLAGS ?= --eta --lb --colsep , --header :
# Experiment ID
EXP ?= PRJNA306490
# Output directory for run information
INFO_OUTDIR ?= run_info
# Output directory for fastq files
DATA_OUTDIR ?= data
# Optional single target sample ID if one of the samples needs to be re-processed
SINGLE_TARGET ?= SRR3033155

# Makefile settings
SHELL := bash
.DELETE_ON_ERROR:
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c
MAKEFLAGS += --warn-undefined-variables --no-print-directory

# Generate the design file.
${DESIGN}:
	@cat << EOF > ${DESIGN}
	SRR,sample,group
	SRR3033154,GLUC_1,GLUC
	SRR3033155,GLUC_2,GLUC
	SRR3033156,ETH_1,ETH
	SRR3033157,ETH_2,ETH
	EOF

# The first target is always the help.
usage::
	@echo "#"
	@echo "# chip-seq.mk: chip-seq data processing pipeline"
	@echo "#"
	@echo "# REF=${REF}"
	@echo "# BAM=${BAM}"
	@echo "#"
	@echo "#"
	@echo "# make run"
	@echo "#"

# Show the design file.
design: ${DESIGN}
	@ls -lh ${DESIGN}

# Ensure the output directories exist
${INFO_OUTDIR} ${DATA_OUTDIR}:
	@mkdir -p $@

# Get the FTP URLs for the experiment
${INFO_OUTDIR}/ftp_urls.txt: | ${INFO_OUTDIR}
	make -f ~/src/run/get_ena_ftps.mk run EXP=${EXP} OUTDIR=${INFO_OUTDIR} > $@

# Invoke the get FTP URLS rule
get_urls: ${INFO_OUTDIR}/ftp_urls.txt
	@ls -lh ${INFO_OUTDIR}

# Downloaed the fastq files using FTP URLs list
get_fastq: get_urls  ${DATA_OUTDIR}
	cat ${INFO_OUTDIR}/ftp_urls.txt | parallel ${FLAGS} \
					make -f ~/src/run/aria.mk run URL={} DIR=${DATA_OUTDIR} -j 5
					touch get_fastq

# Download the reference genome
$(REF):
	curl $(URL) | tar zxv -C refs/
	touch $(REF)

# Get the chromosome sizes
$(CHROM_SIZES):
	curl $(CHROM_SIZES_URL) -d refs > $(CHROM_SIZES)

# Index the reference genome
indexed_genome: $(REF) $(CHROM_SIZES) 
	cat refs/chr*.fa > $(REF) && bwa-mem2 index $(REF) && samtools faidx $(REF)
	touch indexed_genome

# Test the parallel command input output for bwa
test: indexed_genome get_fastq
	cat $(DESIGN) | parallel ${FLAGS} \
				
# Run the bwa-mem2 command in parallel
# Generates BAM, BED, and BigWig files
bwa: $(DESIGN) indexed_genome get_fastq
	cat $(DESIGN) | parallel ${FLAGS} \
				make -f ~/src/run/bwa_mem2.mk run \
				R1=data/{1}_1.fastq.gz R2=data/{1}_2.fastq.gz \
				BAM=bam/{1}.bam REF=${REF}

# Run the bwa-mem2 command for just one sameple
single_target_run: $(DESIGN) ${SINGLE_TARGET} indexed_genome get_fastq
	make -f ~/src/run/bwa_mem2.mk run \
				R1=data/${SINGLE_TARGET}_1.fastq.gz \
				BAM=bam/${SINGLE_TARGET}.bam REF=${REF}

merge: $(DESIGN)
	make -f ~/src/run/merge_bam.mk run \
				BAM=bam PEAKS_DIR=peaks \
				REF=${REF} DESIGN=${DESIGN}

peaks: $(DESIGN)
	make -f ~/src/run/macs2.mk run \
				PEAKS_DIR=peaks \
				REF=${REF} DESIGN=${DESIGN}

motif: $(DESIGN)
	make -f ~/src/run/meme.mk run \
				PEAKS_DIR=peaks \
				REF=${REF} DESIGN=${DESIGN}

run: bwa merge peaks
	@echo "All done"

PHONY: get_fastq indexed_genome run design
