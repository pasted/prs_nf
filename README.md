# PRS-NF: Polygenic Risk Score Pipeline in Nextflow

A Nextflow port of the Snakemake pipeline for calculating Polygenic Risk Scores (PRS) using PRSice, with support for multiple treatment conditions in microglia samples.

## Overview

This pipeline processes genotype data and calculates PRS scores using:
- **Target dataset**: HipSci and IPMAR donor microglia samples
- **Reference dataset**: 1000 Genomes EUR population
- **GWAS summary statistics**: Alzheimer's Disease (Bellenguez)
- **LD reference**: 1000 Genomes or sample LD

## Pipeline Steps

1. **Remove APOE Region** - Excludes APOE region from target genotypes (per Leonenko et al., 2021)
2. **Calculate PRSice with 1000G LD** - Initial PRS calculation using 1000G LD reference
3. **Remove APOE Region (1000G)** - Excludes APOE region from 1000 Genomes reference
4. **Calculate PRS with PRSice (1000G)** - PRS calculation with external LD reference
5. **Extract APOE Positions** - Separately extracts APOE genotypes for analysis
6. **Calculate PCs** - Computes principal components for population structure (30 PCs)
7. **Create AD GWAS Regions from Colocalization** - Filters GWAS SNPs by colocalization with eQTLs
8. **Calculate Microglia-Specific PRS** - Computes PRS for colocalized variants (multiple treatments)
9. **Calculate Microglia-Specific PRS (1000G)** - Computes PRS with 1000G reference

## Requirements

### Software
- Nextflow (>=21.10.0)
- PLINK2
- PRSice (R)
- R with required packages

### Data Files
- VCF files (target and 1000G reference)
- GWAS summary statistics (harmonized format)
- APOE region coordinates file
- APOE SNP list
- Colocalization results (CSV)

## Usage

### Basic execution
```bash
nextflow run main.nf
```

### With custom parameters
```bash
nextflow run main.nf \
    --vcf_target /path/to/target.vcf.gz \
    --vcf_1000g /path/to/1000g.vcf.gz \
    --outdir ./my_results \
    --treatments untreated,LPS,IFN
```

### With a profile (e.g., for HPC)
```bash
nextflow run main.nf -profile hpc
```

## Output

Results are organized in the output directory:
```
results/
├── PRSice/
│   ├── PRSice_noAPOE_LD_from_1000G.all_score
│   ├── 1000G_PRSice_noAPOE.all_score
│   ├── PRSice_noAPOE_microglia_untreated.all_score
│   ├── PRSice_noAPOE_microglia_LPS.all_score
│   ├── PRSice_noAPOE_microglia_IFN.all_score
│   └── ...
├── APOE/
│   ├── hipsci_APOE.vcf
│   └── 1000G_APOE.vcf
├── PCA/
│   ├── hipsci_samples.eigenvec
│   └── 1000G_samples.eigenvec
├── GWAS_regions/
│   ├── AD_coloc_subset_untreated.tsv.gz
│   ├── AD_coloc_subset_LPS.tsv.gz
│   └── AD_coloc_subset_IFN.tsv.gz
├── timeline.html
├── report.html
└── trace.txt
```

## Key Differences from Snakemake

1. **Process-based architecture**: Each rule becomes a process with explicit inputs/outputs
2. **Channel handling**: Automatic file stage-in/out replaces manual path specification
3. **Scalability**: Configuration profiles can be created for different compute environments
4. **Reporting**: Built-in timeline and trace reporting
5. **Module-based design**: Can be restructured as modules for reusability

## PRSice Parameters

The pipeline uses the following PRSice settings:
- **Clumping**: kb=1000, p=0.1, r²=0.1
- **Scoring method**: Average
- **Statistics**: Beta (effect sizes)
- **Allele columns**: Harmonized format (hm_* prefixes)

## Notes

- APOE region exclusion follows Leonenko et al., 2021 (coordinates: chr19:43.9M-46M)
- QC filters applied: MAF 5%, genotyping rate 95%, HWE 0.0001
- 30 principal components calculated for population stratification
- Colocalization filtering with microglia eQTLs (+/- 250kb windows)

## References

- PRSice: https://www.prsice.info/
- PLINK2: https://www.cog-genomics.org/plink/2.0/
- Original Snakemake: https://github.com/TrynkaLab/Perez_Alcantara_pooled_iMGL
