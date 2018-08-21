# GENCODE GRCh37 mapped genome build
# Last updated 2018-08-21

# https://www.gencodegenes.org/releases/grch37_mapped_releases.html
# https://www.gencodegenes.org/releases/28lift37.html
# https://www.ncbi.nlm.nih.gov/grc/human
# https://grch37.ensembl.org

# Release date 2018-04
# Freeze date 2017-11
# GENCODE release 28
# Ensembl release 92

# User-defined parameters ======================================================
biodata_dir="${HOME}/biodata"
species="Homo_sapiens"
build="GRCh37"
source="GENCODE"
release=$GENCODE_RELEASE
cores=8

# Prepare build directory ======================================================
cd "$biodata_dir"
# e.g. grch37_gencode_28
build_dir="${build}_${source}_${release}"
build_dir=$(echo "$build_dir" | tr '[:upper:]' '[:lower:]')
mkdir -p "$build_dir"
cd "$build_dir"

# Transform species name to lowercase
species_dir=$(echo "$species" | tr '[:upper:]' '[:lower:]')

# GENCODE FTP files ============================================================
ftp_dir="ftp://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_${release}/${build}_mapping"

# FASTA ------------------------------------------------------------------------
# Genome sequence, primary assembly (GRCh37)
# GRCh37.primary_assembly.genome.fa.gz
fasta="${build}.primary_assembly.genome.fa"
if [[ ! -f "$fasta" ]]; then
    wget "${ftp_dir}/${fasta}.gz"
    gunzip -c "${fasta}.gz" > "$fasta"
fi

# GTF --------------------------------------------------------------------------
# Comprehensive gene annotation
# gencode.v28lift37.annotation.gtf.gz
gtf="gencode.v${release}lift37.annotation.gtf"
if [[ ! -f "$gtf" ]]; then
    wget "${ftp_dir}/${gtf}.gz"
    gunzip -c "${gtf}.gz" > "$gtf"
fi

# bcbio ========================================================================
bcbio_setup_genome.py \
    -b "$build" \
    -c "$cores" \
    -f "$fasta" \
    -g "$gtf" \
    -i bowtie2 minimap2 seq star \
    -n "$name" \
