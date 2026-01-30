# PRS-NF Pipeline Workflow Diagram

## Data Flow Overview

```
                    ┌─────────────────────────────────────────┐
                    │   INPUTS (VCF, GWAS, Colocalization)   │
                    └────────────┬────────────────────────────┘
                                 │
                    ┌────────────┴────────────┐
                    │                         │
        ┌───────────▼────────────┐  ┌────────▼──────────────┐
        │  VCF Target (HipSci)   │  │  VCF 1000G Reference │
        │  + APOE Region Bed     │  │  + APOE Region Bed   │
        └───────────┬────────────┘  └────────┬──────────────┘
                    │                        │
        ┌───────────▼────────────┐  ┌────────▼──────────────┐
        │ REMOVE_APOE_REGION    │  │REMOVE_APOE_REGION_1000G
        │  (Process 1)          │  │  (Process 3)
        │  plink2 --exclude     │  │  plink2 --exclude
        └───────────┬────────────┘  └────────┬──────────────┘
                    │                        │
        ┌───────────▼────────────┐  ┌────────▼──────────────┐
        │ PLINK noAPOE          │  │ PLINK noAPOE (1000G) │
        │ (bed/bim/fam)         │  │ (bed/bim/fam)        │
        └───────────┬────────────┘  └────────┬──────────────┘
                    │                        │
        ┌───────────┼────────────┐           │
        │           │            │           │
        │     ┌─────▼─────┐      │     ┌─────▼──────┐
        │     │ PRSice LD │      │     │ PRSice 1000G
        │     │ (Process 2)      │     │ (Process 4)
        │     └─────┬─────┘      │     └─────┬──────┘
        │           │            │           │
        └───────────┼────────────┘           │
                    │                        │
                    ├────────────┬───────────┘
                    │            │
                    ▼            ▼
        ┌──────────────────────────────────┐
        │     PRS Score Outputs            │
        │  (1000G_PRSice_noAPOE.all_score) │
        └──────────────────────────────────┘


        Parallel Path: Colocalization Filtering
        ════════════════════════════════════════
        
        ┌────────────────────────────┐
        │ Coloc Results + GWAS Stats │
        └──────────────┬─────────────┘
                       │
                       ▼
        ┌────────────────────────────────────┐
        │ CREATE_AD_GWAS_REGIONS_FROM_COLOC  │
        │ (Process 7) - per treatment         │
        │ - untreated                        │
        │ - LPS                              │
        │ - IFN                              │
        └──────────────┬─────────────────────┘
                       │
        ┌──────────────┴──────────────┐
        │                             │
        ▼                             ▼
    GWAS_coloc_         GWAS_coloc_LPS
    untreated.tsv       .tsv...
    
    
        Microglia-Specific PRS Calculation
        ═════════════════════════════════
        
        ┌─────────────────────────────────────┐
        │ PLINK + GWAS Subset + Treatment ID  │
        └─────────────────────────────────────┘
                       │
        ┌──────────────┴──────────────┐
        │                             │
        ▼                             ▼
    CALCULATE_MICROGLIA_   CALCULATE_MICROGLIA_
    PRS_PRSICE             PRS_PRSICE_1000G
    (Process 8)            (Process 9)
        │                             │
        ├─ untreated                 ├─ untreated
        ├─ LPS                       ├─ LPS
        └─ IFN                       └─ IFN
                │                        │
                ▼                        ▼
        PRSice_noAPOE_       1000G_PRSice_
        microglia_*.scores   noAPOE_microglia_*
        
        
        Auxiliary Outputs
        ════════════════
        
        ┌─────────────────────────────────┐
        │  EXTRACT_APOE_POSITIONS         │
        │  (Process 5)                    │
        │  → hipsci_APOE.vcf              │
        │  → 1000G_APOE.vcf               │
        └─────────────────────────────────┘
        
        ┌─────────────────────────────────┐
        │  CALCULATE_PCS                  │
        │  (Process 6)                    │
        │  → hipsci_samples.eigenvec      │
        │  → 1000G_samples.eigenvec       │
        └─────────────────────────────────┘
```

## Process Execution Graph

```
                            ┌──────────────────────┐
                            │   VCF Input Files    │
                            │   GWAS File          │
                            │   Colocalization     │
                            │   Reference Data     │
                            └──────┬───────────────┘
                                   │
                    ┌──────────────┬┴──────────────┐
                    │              │               │
           Process 1:    Process 3:    Process 5:
        REMOVE_APOE   REMOVE_APOE   EXTRACT_APOE
           REGION      REGION_1000G   POSITIONS
              │              │            │
              ▼              ▼            ▼
         PLINK_        PLINK_1000G   APOE_VCF
         noAPOE        noAPOE        Files
              │              │
              ├──────┬───────┤
              │      │       │
       Process 2:   Process 4:   Process 6:
       PRSICE_LD   PRSICE_1000G  CALCULATE_PCS
              │      │               │
              ▼      ▼               ▼
         PRS_LD  PRS_1000G      PCs Files
         Scores   Scores
              │      │
              └──┬───┘
                 │
         Process 7:
      CREATE_GWAS_
      REGIONS_COLOC
         (per treatment)
              │
         ┌────┴────┬─────┐
         │          │     │
      GWAS_   GWAS_LPS  GWAS_
      untreated  subset   IFN
         │         │      │
         ├─────┬───┤
             │ │ │
        Process 8 & 9:
      MICROGLIA_PRS
      (per treatment)
              │
         ┌────┴────┬─────┐
         │          │     │
       SCORE_  SCORE_LPS SCORE_
       untreated  1000G    IFN
```

## Channel Flow in Nextflow

```
main.nf workflow() {
    
    Create Input Channels
    ↓
    vcf_target → REMOVE_APOE_REGION → plink_target (bed, bim, fam)
    ↓
    plink_target ────→ CALCULATE_PRSICE_LD_1000G ──→ PRS_LD_scores
                  │
                  ├─→ CALCULATE_PCS ──→ PCA_eigenvec
                  │
                  └─→ CALCULATE_MICROGLIA_PRS_PRSICE ──→ Microglia_PRS
    
    vcf_1000g → REMOVE_APOE_REGION_1000G → plink_1000g (bed, bim, fam)
    ↓
    plink_1000g ────→ CALCULATE_PRS_PRSICE_1000G ──→ PRS_1000G_scores
                 │
                 ├─→ EXTRACT_APOE_POSITIONS ──→ APOE_VCF
                 │
                 └─→ CALCULATE_MICROGLIA_PRS_PRSICE_1000G ──→ Microglia_PRS_1000G
    
    coloc + gwas → CREATE_AD_GWAS_REGIONS_FROM_COLOC ──→ GWAS_subsets
                   (per treatment)
                   ↓
                   Used by:
                   - CALCULATE_MICROGLIA_PRS_PRSICE
                   - CALCULATE_MICROGLIA_PRS_PRSICE_1000G
}
```

## Resource Allocation

```
Process                              Resources         Time
─────────────────────────────────────────────────────────────
REMOVE_APOE_REGION                  32 CPUs, 250 GB   12h
CALCULATE_PRSICE_LD_1000G           2 CPUs, 10 GB     4h
REMOVE_APOE_REGION_1000G            32 CPUs, 250 GB   12h
CALCULATE_PRS_PRSICE_1000G          2 CPUs, 10 GB     4h
EXTRACT_APOE_POSITIONS              2 CPUs, 10 GB     4h
CALCULATE_PCS                       32 CPUs, 250 GB   12h
CREATE_AD_GWAS_REGIONS_FROM_COLOC   2 CPUs, 10 GB     4h (×treatments)
CALCULATE_MICROGLIA_PRS_PRSICE      2 CPUs, 10 GB     4h (×treatments)
CALCULATE_MICROGLIA_PRS_PRSICE_1000G 2 CPUs, 10 GB    4h (×treatments)
```

## Output Directory Structure

```
results/
├── PRSice/
│   ├── PRSice_noAPOE_LD_from_1000G.all_score          [Process 2]
│   ├── 1000G_PRSice_noAPOE.all_score                  [Process 4]
│   ├── PRSice_noAPOE_microglia_untreated.all_score    [Process 8]
│   ├── PRSice_noAPOE_microglia_LPS.all_score          [Process 8]
│   ├── PRSice_noAPOE_microglia_IFN.all_score          [Process 8]
│   ├── 1000G_PRSice_noAPOE_microglia_untreated.*.score [Process 9]
│   ├── 1000G_PRSice_noAPOE_microglia_LPS.*.score      [Process 9]
│   └── 1000G_PRSice_noAPOE_microglia_IFN.*.score      [Process 9]
├── APOE/
│   ├── hipsci_APOE.vcf                                 [Process 5]
│   └── 1000G_APOE.vcf                                  [Process 5]
├── PCA/
│   ├── hipsci_samples.eigenvec                         [Process 6]
│   └── 1000G_samples.eigenvec                          [Process 6]
├── GWAS_regions/
│   ├── AD_coloc_subset_untreated.tsv.gz                [Process 7]
│   ├── AD_coloc_subset_LPS.tsv.gz                      [Process 7]
│   └── AD_coloc_subset_IFN.tsv.gz                      [Process 7]
├── timeline.html                                        [Nextflow report]
├── report.html                                          [Nextflow report]
└── trace.txt                                            [Nextflow report]
```

## Key Features Highlighted

✓ **Parallelization**: Treatment-specific calculations run in parallel
✓ **Modularity**: Each process can be run independently or as part of workflow
✓ **Scalability**: Label-based resource allocation
✓ **Reproducibility**: Containerizable, versioned, resumable
✓ **Monitoring**: Built-in timeline and report generation
✓ **Flexibility**: Multiple execution environments supported

---

**Generated for**: PRS-NF Nextflow Pipeline
**Date**: 2026-01-30
