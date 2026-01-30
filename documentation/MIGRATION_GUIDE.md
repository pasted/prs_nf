# Snakemake to Nextflow Migration Guide

This document explains how the original Snakemake pipeline has been ported to Nextflow.

## Pipeline Structure Mapping

### Snakemake Rules → Nextflow Processes

| Snakemake Rule | Nextflow Process | Description |
|---|---|---|
| `remove_APOE_region` | `REMOVE_APOE_REGION` | Remove APOE region from target genotypes |
| `calculate_PRSice_LD_1000Genomes` | `CALCULATE_PRSICE_LD_1000G` | Calculate PRS with 1000G LD reference |
| `remove_APOE_region_1000Genomes` | `REMOVE_APOE_REGION_1000G` | Remove APOE from 1000G genotypes |
| `calculate_PRS_PRSice_1000Genomes` | `CALCULATE_PRS_PRSICE_1000G` | Calculate PRS with PRSice (1000G) |
| `extract_APOE_positions` | `EXTRACT_APOE_POSITIONS` | Extract APOE SNPs separately |
| `calculate_PCs` | `CALCULATE_PCS` | Calculate principal components |
| `create_AD_GWAS_regions_from_coloc` | `CREATE_AD_GWAS_REGIONS_FROM_COLOC` | Filter GWAS by colocalization |
| `calculate_microglia_PRS_PRSice` | `CALCULATE_MICROGLIA_PRS_PRSICE` | Calculate microglia-specific PRS |
| `calculate_microglia_PRS_PRSice_1000Genomes` | `CALCULATE_MICROGLIA_PRS_PRSICE_1000G` | Calculate microglia-specific PRS (1000G) |

## Key Translation Changes

### 1. Wildcards → Channel Operations

**Snakemake:**
```python
rule all:
    input:
        expand("../../data/{prs}/PRSice/1000G_PRSice_noAPOE_microglia_{treatment}.all_score",
               prs=PRS, treatment=TREAT)
```

**Nextflow:**
```groovy
treatments_ch = Channel.fromList(params.treatments)
gwas_subset_ch = CREATE_AD_GWAS_REGIONS_FROM_COLOC.out.flatten()
CALCULATE_MICROGLIA_PRS_PRSICE(plink_target, ld_file, gwas_subset_ch, treatments_ch)
```

### 2. Input/Output Files

**Snakemake:**
```python
rule remove_APOE_region:
    input:
        vcf_target="../../data/imputed_from_kaur/microglia_samples.GRCh38.filtered.vcf.gz"
    output:
        plink_target_noAPOE="../../data/{prs}/all_pools.genotype.noAPOE.bed"
```

**Nextflow:**
```groovy
process REMOVE_APOE_REGION {
    input:
    path vcf_target
    path apoe_region
    
    output:
    tuple path("${params.prs_name}/all_pools.genotype.noAPOE.bed"), 
          path("${params.prs_name}/all_pools.genotype.noAPOE.bim"),
          path("${params.prs_name}/all_pools.genotype.noAPOE.fam"), 
          emit: plink_files
```

### 3. Shell Commands

**Snakemake:** Shell scripts with wildcard substitution
**Nextflow:** Shell scripts with variable interpolation (similar)

Both systems handle inline bash scripts similarly. The main difference is:
- Nextflow automatically stages input files
- Nextflow uses process labels for resource specifications

### 4. Resource Specifications

**Snakemake:**
```python
params:
    memory="-M250000 -R'span[hosts=1] select[mem>250000] rusage[mem=250000]'",
    threads="-n 32"
```

**Nextflow:**
```groovy
process REMOVE_APOE_REGION {
    label 'high_memory'
    
    // Resource config in nextflow.config:
    withLabel: 'high_memory' {
        cpus = 32
        memory = '250 GB'
        time = '12h'
    }
}
```

## Execution Environment

### Running with Snakemake
```bash
snakemake -j 4 --profile hpc
```

### Running with Nextflow
```bash
nextflow run src/main.nf -profile lsf
```

## Key Advantages of the Nextflow Version

1. **Better Error Handling**: Automatic retry mechanisms and error recovery
2. **Scalability**: Native support for multiple executors (SLURM, LSF, HPC, Cloud)
3. **Reproducibility**: Built-in containerization support (Docker/Singularity)
4. **Monitoring**: Web-based execution reports and timeline visualization
5. **Modularity**: Can be restructured into reusable modules
6. **Resume Capability**: `nextflow run src/main.nf -resume` to continue from where it failed

## Configuration Profiles

### Available Profiles
- **standard**: Local execution
- **lsf**: LSF cluster (HGI Farm)
- **slurm**: SLURM cluster
- **docker**: Docker containerized execution
- **singularity**: Singularity container execution

### Using Profiles
```bash
nextflow run src/main.nf -profile lsf -c configuration/nextflow.config
```

## Parameter Management

**Snakemake:** Defined in the Snakefile or config files
**Nextflow:** Centralized in `configuration/nextflow.config`, can be overridden at runtime:

```bash
nextflow run src/main.nf --outdir /custom/output --prs_name my_prs
```

## Data Flow Differences

### Snakemake
- Linear execution from inputs to outputs
- Wildcards used for parameterization
- File paths managed explicitly in scripts

### Nextflow
- Event-driven (channel-based)
- Implicit file staging and moving
- Operators for combining channels:
  - `combine()`: Cross-product
  - `join()`: Join on key
  - `mix()`: Merge channels
  - `groupTuple()`: Group by key

## Troubleshooting

### File Not Found
**Nextflow:** Check that input files are properly pathed and exist
```bash
nextflow run src/main.nf --vcf_target /absolute/path/to/file.vcf.gz
```

### Process Fails
**Nextflow:** Check the work directory for error logs
```bash
# View trace for failed task
cat work/*/.*/.command.log
```

### Memory Issues
**Nextflow:** Adjust labels in `configuration/nextflow.config`
```groovy
withLabel: 'high_memory' {
    memory = '500 GB'
}
```

## Additional Resources

- [Nextflow Documentation](https://www.nextflow.io/docs/)
- [DSL2 Guide](https://www.nextflow.io/docs/latest/dsl2.html)
- [PRSice Documentation](https://www.prsice.info/)
- [PLINK2 Documentation](https://www.cog-genomics.org/plink/2.0/)

## Testing

To test the pipeline locally with a subset:
```bash
nextflow run src/main.nf -profile standard \
    --vcf_target test_data/sample.vcf.gz \
    --outdir test_results
```

## Migration Checklist

- [x] All rules converted to processes
- [x] Parameters centralized in configuration
- [x] Resource labels implemented
- [x] Execution profiles created
- [x] Error handling improved
- [x] Documentation updated
- [ ] Integration tests created (optional)
- [ ] Container images built (optional)
