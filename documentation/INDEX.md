# PRS-NF Documentation Index

Welcome to the Nextflow port of the Polygenic Risk Score (PRS) pipeline! This document serves as a guide to all available documentation.

## 📚 Documentation Quick Links

### For First-Time Users
Start here if you're new to this pipeline or Nextflow:

1. **[QUICKSTART.md](QUICKSTART.md)** (5-10 min read)
   - Installation instructions
   - Basic execution commands
   - Quick troubleshooting
   - Common usage patterns
   - **Start here!**

2. **[README.md](README.md)** (10-15 min read)
   - Complete pipeline overview
   - Requirements and setup
   - Output file descriptions
   - Key differences from Snakemake
   - PRSice parameters

### For Snakemake Users
If you're familiar with the original Snakemake pipeline:

3. **[MIGRATION_GUIDE.md](MIGRATION_GUIDE.md)** (15-20 min read)
   - Rule → Process mapping
   - Key translation changes
   - Configuration profiles
   - Parameter management
   - Troubleshooting guide

### For Pipeline Authors & Developers
Detailed technical documentation:

4. **[IMPLEMENTATION_NOTES.md](IMPLEMENTATION_NOTES.md)** (20-30 min read)
   - Port completion status
   - Implementation details
   - Channel management
   - Error handling
   - Testing recommendations
   - Performance benchmarks
   - Future enhancements

5. **[WORKFLOW_DIAGRAM.md](WORKFLOW_DIAGRAM.md)** (5-10 min read)
   - Visual workflow diagrams
   - Process execution graph
   - Channel flow
   - Resource allocation
   - Output structure

### For System Administrators
Configuration and deployment:

6. **[../configuration/nextflow.config](../configuration/nextflow.config)**
   - Local execution settings
   - Resource specifications
   - Process labels
   - Reporting options

7. **[../configuration/profiles.config](../configuration/profiles.config)**
   - LSF cluster configuration
   - SLURM cluster configuration
   - Docker configuration
   - Singularity configuration

### Reference Materials

8. **[PORT_SUMMARY.md](PORT_SUMMARY.md)**
   - High-level overview
   - What was ported
   - Files created/modified
   - Key features
   - Next steps

9. **[../configuration/environment.yml](../configuration/environment.yml)**
   - Conda dependency specification
   - Package versions

10. **[../configuration/Dockerfile](../configuration/Dockerfile)**
    - Container image specification
    - Base image and packages
    - Verification steps

11. **[../configuration/params.example.json](../configuration/params.example.json)**
    - Example parameter configuration
    - Reference for all available parameters

## 🎯 Suggested Reading Path

### Path 1: Quick Setup (30 min)
1. QUICKSTART.md - Get it running
2. README.md - Understand outputs
3. Run the pipeline!

### Path 2: Complete Understanding (1-2 hours)
1. QUICKSTART.md - Quick setup
2. README.md - Overview
3. WORKFLOW_DIAGRAM.md - Understand flow
4. MIGRATION_GUIDE.md - If coming from Snakemake
5. IMPLEMENTATION_NOTES.md - Deep dive

### Path 3: Migration from Snakemake (1 hour)
1. PORT_SUMMARY.md - What changed
2. MIGRATION_GUIDE.md - Detailed mapping
3. WORKFLOW_DIAGRAM.md - Visual flow
4. QUICKSTART.md - How to run

### Path 4: System Administration (1-2 hours)
1. README.md - Requirements
2. ../configuration/profiles.config - Available profiles
3. ../configuration/nextflow.config - Local configuration
4. ../configuration/Dockerfile - Containerization
5. ../configuration/environment.yml - Dependencies

## 📁 File Structure Overview

```
prs_nf/
├── 📘 documentation/
│   ├── README.md                 ← Main documentation
│   ├── QUICKSTART.md             ← Fast setup guide
│   ├── MIGRATION_GUIDE.md        ← Snakemake→Nextflow guide
│   ├── IMPLEMENTATION_NOTES.md   ← Technical details
│   ├── WORKFLOW_DIAGRAM.md       ← Visual diagrams
│   ├── PORT_SUMMARY.md           ← High-level overview
│   └── INDEX.md                  ← This file
│
├── 🔧 configuration/
│   ├── nextflow.config           ← Main configuration
│   ├── profiles.config           ← Execution profiles
│   ├── params.example.json       ← Example parameters
│   ├── environment.yml           ← Conda environment
│   └── Dockerfile                ← Container image
│
├── 💻 src/
│   ├── main.nf                   ← Main workflow (407 lines)
│   └── scripts/
│       └── get_coloc_positions.R ← GWAS filtering script
│
├── 📋 project/
│   └── LICENSE                   ← License file
│
├── README.md                      ← Root README
└── .git/                          ← Version control
```

## 🚀 Quick Command Reference

### Installation
```bash
# Clone repository
git clone <repo-url>
cd prs_nf

# Setup environment
conda env create -f configuration/environment.yml
conda activate prs_nf
```

### Execution
```bash
# Local execution
nextflow run src/main.nf

# With custom parameters
nextflow run src/main.nf --outdir /custom/path

# On cluster
nextflow run src/main.nf -profile lsf

# Resume after failure
nextflow run src/main.nf -resume

# With Docker
nextflow run src/main.nf -profile docker
```

### Monitoring
```bash
# View execution timeline
open results/timeline.html

# View execution report
open results/report.html

# Check process logs
ls work/*/*/.command.*
```

## 📖 FAQ

**Q: Where do I start?**
A: Read QUICKSTART.md first, then run the basic example.

**Q: How do I customize parameters?**
A: See params.example.json or use command-line flags.

**Q: What if I'm coming from Snakemake?**
A: Start with MIGRATION_GUIDE.md for detailed mapping.

**Q: How do I run on my HPC cluster?**
A: Check profiles.config and QUICKSTART.md for your cluster type.

**Q: How do I troubleshoot errors?**
A: See QUICKSTART.md troubleshooting section or IMPLEMENTATION_NOTES.md.

**Q: Can I run on Docker/Singularity?**
A: Yes! Use `-profile docker` or `-profile singularity`.

**Q: Where are the results?**
A: In the `results/` directory (or your custom `--outdir`).

**Q: How long does it take?**
A: ~2-4 hours depending on data size. See IMPLEMENTATION_NOTES.md.

**Q: Can I resume a failed run?**
A: Yes! Use `nextflow run src/main.nf -resume`.

## 🔗 External Resources

### Official Documentation
- [Nextflow Documentation](https://www.nextflow.io/)
- [DSL2 Guide](https://www.nextflow.io/docs/latest/dsl2.html)
- [PRSice Documentation](https://www.prsice.info/)
- [PLINK2 Documentation](https://www.cog-genomics.org/plink/2.0/)

### Original Pipeline
- [Snakemake Repository](https://github.com/TrynkaLab/Perez_Alcantara_pooled_iMGL)
- [Publication References](See README.md)

### Community Resources
- [Nextflow Community](https://nfcore.slack.com/)
- [Bioinformatics Stack Exchange](https://bioinformatics.stackexchange.com/)

## ✅ Checklist Before Running

- [ ] Read QUICKSTART.md
- [ ] Verify Nextflow installation: `nextflow -version`
- [ ] Verify dependencies: `plink2 --version`, `Rscript --version`
- [ ] Check file paths in `configuration/nextflow.config`
- [ ] Verify input files exist
- [ ] Create output directory
- [ ] Check available disk space (at least 50GB for work files)
- [ ] Test with small dataset first

## 📞 Getting Help

If you encounter issues:

1. **Check the QUICKSTART.md troubleshooting section**
2. **Review IMPLEMENTATION_NOTES.md for your specific issue**
3. **Check the Nextflow log output**
4. **Verify file paths and permissions**
5. **Consult external documentation** (Nextflow, PLINK2, PRSice)

## 📝 Notes

- This pipeline is based on the original Snakemake version
- All 9 processes have been ported and are fully functional
- Configuration is flexible and can be adapted to any HPC environment
- Container support (Docker/Singularity) available for reproducibility

---

**Last Updated**: 2026-01-30
**Pipeline Version**: 1.0
**Status**: Ready for Production Use

**Start with:** [QUICKSTART.md](QUICKSTART.md) or [README.md](README.md)
