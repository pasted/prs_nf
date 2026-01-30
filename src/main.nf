#!/usr/bin/env nextflow

nextflow.enable.dsl=2

// Pipeline parameters
params.vcf_target = "../../data/imputed_from_kaur/microglia_samples.GRCh38.filtered.vcf.gz"
params.vcf_1000g = "/lustre/scratch123/hgi/teams/trynka/resources/1000g/1000G/release/20220422/b38/EUR/1000G_EUR_maf05perc_biallelic_nonmissing_nochr_withrsid.vcf.gz"
params.gwas = "/lustre/scratch123/hgi/teams/trynka/resources/summary_statistics/public/GCST90027158/harmonised/35379992-GCST90027158-MONDO_0004975.h.tsv.gz"
params.coloc_results = "../../../OTAR2065_sc_eQTL/data/results/8.colocalisation_analysis/coloc_results/all_GWAS_colocalisations.csv"
params.prsice_dir = "/software/hgi/envs/conda/team217/ma23/PRSice"
params.apoe_snps = "../../data/prs_ad_bellenguez/APOE_snps.txt"
params.apoe_region = "../../data/prs_ad_bellenguez/apoe_region_coords.bed"
params.treatments = ["untreated", "LPS", "IFN"]
params.prs_name = "prs_ad_bellenguez"
params.outdir = "./results"

log.info """\
    P R S - N F   P I P E L I N E
    ====================================
    VCF Target          : ${params.vcf_target}
    VCF 1000G           : ${params.vcf_1000g}
    GWAS Summary Stats  : ${params.gwas}
    PRSice Directory    : ${params.prsice_dir}
    Treatments          : ${params.treatments}
    Output Directory    : ${params.outdir}
""".stripIndent()

// Define processes
process REMOVE_APOE_REGION {
    label 'high_memory'
    
    input:
    path vcf_target
    path apoe_region
    
    output:
    tuple path("${params.prs_name}/all_pools.genotype.noAPOE.bed"), 
          path("${params.prs_name}/all_pools.genotype.noAPOE.bim"),
          path("${params.prs_name}/all_pools.genotype.noAPOE.fam"), emit: plink_files
    
    script:
    """
    set +o pipefail
    
    mkdir -p ${params.prs_name}
    
    # Convert VCF to PLINK format
    plink2 --vcf ${vcf_target} --make-bed --out ${params.prs_name}/microglia_samples.GRCh38.filtered
    
    # Copy PLINK files
    cd ${params.prs_name}
    cp --symbolic-link ../microglia_samples.GRCh38.filtered.bed . || cp ../microglia_samples.GRCh38.filtered.bed .
    cp --symbolic-link ../microglia_samples.GRCh38.filtered.fam . || cp ../microglia_samples.GRCh38.filtered.fam .
    
    # Remove "chr" prefix from chromosomes in bim file
    awk 'BEGIN{FS=OFS="\\t"} {sub("chr", "", \$2)} 1' ../microglia_samples.GRCh38.filtered.bim > microglia_samples.GRCh38.filtered.bim
    
    # Remove APOE region
    plink2 --bfile ./microglia_samples.GRCh38.filtered \\
        --exclude range ${apoe_region} \\
        --make-bed \\
        --out ./all_pools.genotype.noAPOE
    """
}

process CALCULATE_PRSICE_LD_1000G {
    label 'high_memory'
    publishDir "${params.outdir}/PRSice", mode: 'copy'
    
    input:
    tuple path(bed), path(bim), path(fam)
    path ld_file
    path gwas
    
    output:
    path "PRSice_noAPOE_LD_from_1000G.all_score"
    
    script:
    """
    mkdir -p PRSice
    
    Rscript ${params.prsice_dir}/PRSice.R \\
        --dir ${params.prsice_dir} \\
        --out ./PRSice_noAPOE_LD_from_1000G \\
        --prsice ${params.prsice_dir}/bin/PRSice \\
        --base ${gwas} \\
        --target ${bed.getParent()}/\$(basename ${bed} .bed) \\
        --binary-target T \\
        --ld ${ld_file.getParent()}/\$(basename ${ld_file} .bim) \\
        --thread 1 \\
        --beta --stat hm_beta \\
        --snp hm_variant_id \\
        --chr hm_chrom \\
        --bp hm_pos \\
        --A1 hm_effect_allele \\
        --A2 hm_other_allele \\
        --pvalue p_value \\
        --clump-kb 1000kb \\
        --clump-p 0.100000 \\
        --clump-r2 0.100000 \\
        --score avg \\
        --no-regress
    """
}

process REMOVE_APOE_REGION_1000G {
    label 'high_memory'
    
    input:
    path vcf_1000g
    path apoe_region
    path bim_target
    
    output:
    tuple path("${params.prs_name}/1000G_noAPOE.bed"),
          path("${params.prs_name}/1000G_noAPOE.bim"),
          path("${params.prs_name}/1000G_noAPOE.fam"), emit: plink_files
    
    script:
    """
    set +o pipefail
    
    mkdir -p ${params.prs_name}
    
    # Convert 1000G VCF to PLINK
    plink2 --vcf ${vcf_1000g} \\
        --max-alleles 2 \\
        --allow-extra-chr --chr 1-22 \\
        --make-bed \\
        --out ${params.prs_name}/1000G_EUR_maf05perc_biallelic_nonmissing_nochr_withrsid
    
    cd ${params.prs_name}
    
    # Fix variant IDs
    cp --symbolic-link ../1000G_EUR_maf05perc_biallelic_nonmissing_nochr_withrsid.bed 1000G_EUR_maf05perc_biallelic_nonmissing_nochr_withrsid_checked.bed || cp ../1000G_EUR_maf05perc_biallelic_nonmissing_nochr_withrsid.bed 1000G_EUR_maf05perc_biallelic_nonmissing_nochr_withrsid_checked.bed
    cp --symbolic-link ../1000G_EUR_maf05perc_biallelic_nonmissing_nochr_withrsid.fam 1000G_EUR_maf05perc_biallelic_nonmissing_nochr_withrsid_checked.fam || cp ../1000G_EUR_maf05perc_biallelic_nonmissing_nochr_withrsid.fam 1000G_EUR_maf05perc_biallelic_nonmissing_nochr_withrsid_checked.fam
    
    # Create proper variant IDs
    awk 'BEGIN{FS=OFS="\\t"} { \$2 = \$1 "_" \$4 "_" \$6 "_" \$5 }1' ../1000G_EUR_maf05perc_biallelic_nonmissing_nochr_withrsid.bim > 1000G_EUR_maf05perc_biallelic_nonmissing_nochr_withrsid_checked.bim
    
    # Remove APOE region and keep only variants from target
    plink2 --bfile ./1000G_EUR_maf05perc_biallelic_nonmissing_nochr_withrsid_checked \\
        --exclude range ${apoe_region} \\
        --extract ${bim_target} \\
        --make-bed \\
        --out ./1000G_noAPOE
    """
}

process CALCULATE_PRS_PRSICE_1000G {
    label 'medium_memory'
    publishDir "${params.outdir}/PRSice", mode: 'copy'
    
    input:
    tuple path(bed), path(bim), path(fam)
    path gwas
    
    output:
    path "1000G_PRSice_noAPOE.all_score"
    
    script:
    """
    mkdir -p PRSice
    
    Rscript ${params.prsice_dir}/PRSice.R \\
        --dir ${params.prsice_dir} \\
        --out ./PRSice/1000G_PRSice_noAPOE \\
        --prsice ${params.prsice_dir}/bin/PRSice \\
        --base ${gwas} \\
        --target ${bed.getParent()}/\$(basename ${bed} .bed) \\
        --binary-target T \\
        --thread 1 \\
        --beta --stat hm_beta \\
        --snp hm_variant_id \\
        --chr hm_chrom \\
        --bp hm_pos \\
        --A1 hm_effect_allele \\
        --A2 hm_other_allele \\
        --pvalue p_value \\
        --clump-kb 1000kb \\
        --clump-p 0.100000 \\
        --clump-r2 0.100000 \\
        --score avg \\
        --no-regress
    """
}

process EXTRACT_APOE_POSITIONS {
    label 'medium_memory'
    publishDir "${params.outdir}/APOE", mode: 'copy'
    
    input:
    path bim_hipsci
    path bim_1000g
    path apoe_snps
    
    output:
    path "hipsci_APOE.vcf"
    path "1000G_APOE.vcf"
    
    script:
    """
    plink2 --bfile ${bim_hipsci.getParent()}/\$(basename ${bim_hipsci} .bim) \\
        --extract ${apoe_snps} \\
        --recode vcf --out hipsci_APOE
    
    plink2 --bfile ${bim_1000g.getParent()}/\$(basename ${bim_1000g} .bim) \\
        --extract ${apoe_snps} \\
        --recode vcf --out 1000G_APOE
    """
}

process CALCULATE_PCS {
    label 'high_memory'
    publishDir "${params.outdir}/PCA", mode: 'copy'
    
    input:
    path bim_hipsci
    path bim_1000g
    
    output:
    path "hipsci_samples.eigenvec"
    path "1000G_samples.eigenvec"
    
    script:
    """
    plink2 --bfile ${bim_hipsci.getParent()}/\$(basename ${bim_hipsci} .bim) \\
        --geno 0.05 \\
        --maf 0.05 \\
        --hwe 0.0001 \\
        --pca 30 \\
        --out hipsci_samples
    
    plink2 --bfile ${bim_1000g.getParent()}/\$(basename ${bim_1000g} .bim) \\
        --geno 0.05 \\
        --maf 0.05 \\
        --hwe 0.0001 \\
        --pca 30 \\
        --out 1000G_samples
    """
}

process CREATE_AD_GWAS_REGIONS_FROM_COLOC {
    label 'medium_memory'
    publishDir "${params.outdir}/GWAS_regions", mode: 'copy'
    
    input:
    path coloc_results
    path gwas
    val treatment
    
    output:
    path "AD_coloc_subset_${treatment}.tsv.gz"
    
    script:
    """
    # This would typically call an R script that filters GWAS by colocalization results
    # For now, creating a placeholder that shows the structure
    Rscript ${workflow.projectDir}/scripts/get_coloc_positions.R \\
        ${coloc_results} \\
        ${treatment} \\
        ${gwas} \\
        AD_coloc_subset_${treatment}.tsv.gz
    """
}

process CALCULATE_MICROGLIA_PRS_PRSICE {
    label 'medium_memory'
    publishDir "${params.outdir}/PRSice", mode: 'copy'
    
    input:
    tuple path(bed), path(bim), path(fam)
    path ld_file
    path gwas_subset
    val treatment
    
    output:
    path "PRSice_noAPOE_microglia_${treatment}.all_score"
    
    script:
    """
    mkdir -p PRSice
    
    Rscript ${params.prsice_dir}/PRSice.R \\
        --dir ${params.prsice_dir} \\
        --out ./PRSice/PRSice_noAPOE_microglia_${treatment} \\
        --prsice ${params.prsice_dir}/bin/PRSice \\
        --base ${gwas_subset} \\
        --target ${bed.getParent()}/\$(basename ${bed} .bed) \\
        --binary-target T \\
        --ld ${ld_file.getParent()}/\$(basename ${ld_file} .bim) \\
        --thread 1 \\
        --beta --stat hm_beta \\
        --snp hm_variant_id \\
        --chr hm_chrom \\
        --bp hm_pos \\
        --A1 hm_effect_allele \\
        --A2 hm_other_allele \\
        --pvalue p_value \\
        --clump-kb 1000kb \\
        --clump-p 0.100000 \\
        --clump-r2 0.100000 \\
        --score avg \\
        --no-regress
    """
}

process CALCULATE_MICROGLIA_PRS_PRSICE_1000G {
    label 'medium_memory'
    publishDir "${params.outdir}/PRSice", mode: 'copy'
    
    input:
    tuple path(bed), path(bim), path(fam)
    path gwas_subset
    val treatment
    
    output:
    path "1000G_PRSice_noAPOE_microglia_${treatment}.all_score"
    
    script:
    """
    mkdir -p PRSice
    
    Rscript ${params.prsice_dir}/PRSice.R \\
        --dir ${params.prsice_dir} \\
        --out ./PRSice/1000G_PRSice_noAPOE_microglia_${treatment} \\
        --prsice ${params.prsice_dir}/bin/PRSice \\
        --base ${gwas_subset} \\
        --target ${bed.getParent()}/\$(basename ${bed} .bed) \\
        --binary-target T \\
        --thread 1 \\
        --beta --stat hm_beta \\
        --snp hm_variant_id \\
        --chr hm_chrom \\
        --bp hm_pos \\
        --A1 hm_effect_allele \\
        --A2 hm_other_allele \\
        --pvalue p_value \\
        --clump-kb 1000kb \\
        --clump-p 0.100000 \\
        --clump-r2 0.100000 \\
        --score avg \\
        --no-regress
    """
}

// Workflow
workflow {
    
    // Create channels for input files
    vcf_target = file(params.vcf_target, checkIfExists: true)
    vcf_1000g = file(params.vcf_1000g, checkIfExists: true)
    gwas = file(params.gwas, checkIfExists: true)
    coloc_results = file(params.coloc_results, checkIfExists: true)
    apoe_region = file(params.apoe_region, checkIfExists: true)
    apoe_snps = file(params.apoe_snps, checkIfExists: true)
    
    // Step 1: Remove APOE region from target genotypes
    REMOVE_APOE_REGION(vcf_target, apoe_region)
    plink_target = REMOVE_APOE_REGION.out.plink_files
    
    // Step 2: Calculate PRSice with 1000G LD
    ld_file = file("${params.prs_name}/1000G_EUR_maf05perc_biallelic_nonmissing_nochr_withrsid_checked.bim")
    CALCULATE_PRSICE_LD_1000G(plink_target, ld_file, gwas)
    
    // Step 3: Remove APOE region from 1000G genotypes
    REMOVE_APOE_REGION_1000G(vcf_1000g, apoe_region, REMOVE_APOE_REGION.out.plink_files.map { it[1] })
    plink_1000g = REMOVE_APOE_REGION_1000G.out.plink_files
    
    // Step 4: Calculate PRS with PRSice using 1000G
    CALCULATE_PRS_PRSICE_1000G(plink_1000g, gwas)
    
    // Step 5: Extract APOE positions
    EXTRACT_APOE_POSITIONS(
        REMOVE_APOE_REGION.out.plink_files.map { it[1] },
        REMOVE_APOE_REGION_1000G.out.plink_files.map { it[1] },
        apoe_snps
    )
    
    // Step 6: Calculate PCs
    CALCULATE_PCS(
        REMOVE_APOE_REGION.out.plink_files.map { it[1] },
        REMOVE_APOE_REGION_1000G.out.plink_files.map { it[1] }
    )
    
    // Step 7: Create AD GWAS regions from colocalization
    treatments_ch = Channel.fromList(params.treatments)
    CREATE_AD_GWAS_REGIONS_FROM_COLOC(coloc_results, gwas, treatments_ch)
    
    // Step 8: Calculate microglia-specific PRS with PRSice
    gwas_subset_ch = CREATE_AD_GWAS_REGIONS_FROM_COLOC.out.flatten()
    treatments_ch2 = Channel.fromList(params.treatments)
    
    CALCULATE_MICROGLIA_PRS_PRSICE(
        plink_target,
        ld_file,
        gwas_subset_ch,
        treatments_ch2
    )
    
    // Step 9: Calculate microglia-specific PRS with PRSice for 1000G
    CALCULATE_MICROGLIA_PRS_PRSICE_1000G(
        plink_1000g,
        gwas_subset_ch,
        treatments_ch2
    )
}