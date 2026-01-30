#!/usr/bin/env Rscript

# Script to filter GWAS summary statistics by colocalization results
# Takes colocalization results and creates treatment-specific GWAS subsets

library(tidyverse)
library(data.table)

args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 4) {
    cat("Usage: Rscript get_coloc_positions.R <coloc_results> <treatment> <gwas_file> <output>\n")
    cat("Example: Rscript get_coloc_positions.R coloc.csv LPS gwas.tsv.gz output.tsv.gz\n")
    quit(status = 1)
}

coloc_file <- args[1]
treatment <- args[2]
gwas_file <- args[3]
output_file <- args[4]

# Read colocalization results
cat("Reading colocalization results from:", coloc_file, "\n")
coloc_results <- read.csv(coloc_file, stringsAsFactors = FALSE)

# Filter for the specific treatment
# Assuming the coloc_results has columns: gene_id, variant_id, treatment, H4_prob, etc.
cat("Filtering for treatment:", treatment, "\n")
coloc_filtered <- coloc_results %>%
    filter(grepl(treatment, treatment, ignore.case = TRUE)) %>%
    pull(variant_id) %>%
    unique()

cat("Found", length(coloc_filtered), "colocalized variants for", treatment, "\n")

# Read GWAS summary statistics
cat("Reading GWAS summary statistics from:", gwas_file, "\n")
gwas <- fread(gwas_file, sep = "\t", header = TRUE)

# Filter GWAS by colocalized variants
# Assuming variant_id column exists or needs to be constructed
if ("hm_variant_id" %in% names(gwas)) {
    gwas_subset <- gwas[hm_variant_id %in% coloc_filtered]
} else if ("variant_id" %in% names(gwas)) {
    gwas_subset <- gwas[variant_id %in% coloc_filtered]
} else {
    # Construct variant_id from chr_pos_ref_alt
    gwas[, variant_id := paste(hm_chrom, hm_pos, hm_other_allele, hm_effect_allele, sep = "_")]
    gwas_subset <- gwas[variant_id %in% coloc_filtered]
}

cat("GWAS subset has", nrow(gwas_subset), "variants\n")

# Write output
cat("Writing subset to:", output_file, "\n")
fwrite(gwas_subset, file = output_file, sep = "\t", compress = "gzip")

cat("Done!\n")
