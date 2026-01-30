# Quick Start Guide for PRS-NF

## Installation

### 1. Install Nextflow
```bash
curl -s https://get.nextflow.io | bash
chmod +x nextflow
./nextflow self-update
```

### 2. Install Dependencies
```bash
# Option A: Using Conda
conda env create -f configuration/environment.yml
conda activate prs_nf

# Option B: Using Docker
docker build -t prs-nf:latest configuration/
```

### 3. Install PRSice
```bash
# Download and install PRSice manually or via conda
# Update params.prsice_dir to point to the installation
```

## Quick Start

### Running with Test Data (Recommended First Step)
```bash
# Create test directory structure
mkdir -p test_data
cp /path/to/real/data/sample.vcf.gz test_data/

# Run with test data
nextflow run src/main.nf \
    --vcf_target test_data/sample.vcf.gz \
    --outdir test_results \
    -profile standard
```

### Running Full Pipeline

#### On Local Machine
```bash
nextflow run src/main.nf -profile standard
```

#### On LSF Cluster (HGI Farm)
```bash
nextflow run src/main.nf -profile lsf
```

#### On SLURM Cluster
```bash
nextflow run src/main.nf -profile slurm
```

#### With Docker
```bash
nextflow run src/main.nf -profile docker
```

## Customizing Parameters

### Method 1: Command Line
```bash
nextflow run src/main.nf \
    --vcf_target /path/to/target.vcf.gz \
    --vcf_1000g /path/to/1000g.vcf.gz \
    --outdir ./my_results \
    --treatments untreated,LPS,IFN
```

### Method 2: Parameter File
```bash
# Create my_params.json with custom values
cp configuration/params.example.json my_params.json
# Edit my_params.json as needed
nextflow run src/main.nf -params-file my_params.json
```

### Method 3: Configuration File
```bash
# Edit configuration/nextflow.config and run
nextflow run src/main.nf -c configuration/my_config.config
```

## Monitoring Pipeline Execution

### During Execution
```bash
# In another terminal, check process status
watch -n 5 "nextflow log -s"
```

### After Execution
```bash
# View execution timeline
open results/timeline.html

# View execution report
open results/report.html

# View execution trace
cat results/trace.txt
```

## Resuming Failed Runs

If a process fails and you fix the issue, you can resume:
```bash
nextflow run src/main.nf -resume
```

The `-resume` flag will re-run only failed tasks and their descendants.

## Output Organization

All results are saved to `${outdir}` (default: `./results/`):

```
results/
├── PRSice/                          # All PRS scores
│   ├── PRSice_noAPOE_LD_from_1000G.all_score
│   ├── 1000G_PRSice_noAPOE.all_score
│   ├── PRSice_noAPOE_microglia_untreated.all_score
│   ├── PRSice_noAPOE_microglia_LPS.all_score
│   ├── PRSice_noAPOE_microglia_IFN.all_score
│   └── 1000G_PRSice_noAPOE_microglia_*.all_score
├── APOE/                            # APOE genotypes
│   ├── hipsci_APOE.vcf
│   └── 1000G_APOE.vcf
├── PCA/                             # Principal components
│   ├── hipsci_samples.eigenvec
│   └── 1000G_samples.eigenvec
├── GWAS_regions/                    # Treatment-specific GWAS subsets
│   ├── AD_coloc_subset_untreated.tsv.gz
│   ├── AD_coloc_subset_LPS.tsv.gz
│   └── AD_coloc_subset_IFN.tsv.gz
├── timeline.html                    # Execution timeline
├── report.html                      # Execution report
└── trace.txt                        # Detailed execution trace
```

## Troubleshooting

### Issue: Command not found (plink2, Rscript)
**Solution:** Ensure your environment is activated or Docker/Singularity is properly configured
```bash
# If using conda
conda activate prs_nf

# If using Docker
docker build -t prs-nf:latest configuration/
nextflow run src/main.nf -profile docker
```

### Issue: File not found errors
**Solution:** Use absolute paths for input files
```bash
nextflow run main.nf \
    --vcf_target /absolute/path/to/file.vcf.gz \
    --apoe_region /absolute/path/to/apoe_region.bed
```

### Issue: Out of memory
**Solution:** Increase memory in configuration
```groovy
// In nextflow.config
process {
    withLabel: 'high_memory' {
        memory = '500 GB'  # Increase from 250 GB
    }
}
```

### Issue: Permission denied
**Solution:** Check working directory permissions
```bash
ls -ld .  # Check current directory permissions
chmod 755 .  # Make sure directory is accessible
```

## Useful Nextflow Commands

```bash
# Show all executed tasks and their status
nextflow log

# Display detailed information about a specific run
nextflow log last

# Clean up work directories (be careful!)
nextflow clean -f

# View available options
nextflow run src/main.nf --help

# List process definitions
nextflow run src/main.nf -list
```

## Advanced Usage

### Changing Number of Parallel Tasks
```bash
nextflow run src/main.nf -qs 10  # Limit to 10 queued jobs
```

### Specifying Work Directory
```bash
nextflow run src/main.nf -w /custom/work/dir
```

### Using Different Java Memory Settings
```bash
NXF_OPTS='-Xmx8g' nextflow run src/main.nf
```

## Performance Tips

1. **Use SSD for work directory** for better I/O performance
2. **Increase `maxRetries`** for network-related failures
3. **Use profile-specific configurations** for your HPC system
4. **Monitor memory usage** and adjust labels accordingly
5. **Parallelize treatment calculations** by expanding treatment channels

## Getting Help

- Check the [README.md](../README.md) for pipeline overview
- See [MIGRATION_GUIDE.md](MIGRATION_GUIDE.md) for Snakemake differences
- Visit [Nextflow Documentation](https://www.nextflow.io/docs/)
- Check PRSice logs in `${outdir}/PRSice/` directory

## Next Steps

1. Install dependencies (Nextflow, PLINK2, R with PRSice)
2. Verify paths in `configuration/nextflow.config` match your system
3. Run with `-profile standard` for initial testing
4. Switch to `-profile lsf` (or appropriate cluster) for production runs
5. Monitor execution and adjust parameters as needed
