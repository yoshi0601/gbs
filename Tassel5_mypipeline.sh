#!/bin/bash

## USER SETTINGS
RUN_PIPELINE='/home/gbsuser/tassel-5-standalone/run_pipeline.pl'
ENZYME='KpnI-MspI'
KEYFILE='key.txt'
#TAXA='IBMGBSTaxaList.txt'
#TNAME="IBM" 
INPUT_DIR='fastq/'
REFSEQ='/home/gbsuser/nipponbare_ref/IRGSP-1.0_genome.fasta'
VCFTOOLS='/home/gbsuser/tool/vcftools_0.1.13/cpp/vcftools'

## ANALYSIS PARAMETERS BY USERS
BWA='/usr/local/bin/bwa'

#####################
#MAIN
###################
TEMPDIR='tempDir/'
DB=$TEMPDIR'GBSv2.db'
HISTORY=$TEMPDIR'command_hisotories.txt'
DRYRUN="run"
[ $1 ] && DRYRUN=$1

[ $DRYRUN == "run" ] && rm -rf $TEMPDIR
[ $DRYRUN == "run" ] && mkdir $TEMPDIR
[ $DRYRUN == "run" ] && rm $HISTORY
[ $DRYRUN == "run" ] && rm GBSv2.db


# Step1: GBSSeqToTagDBPlugin:
LOG=$TEMPDIR'1_Log_GBSSeqToTagDBPlugin_'$(date +%Y%m%d-%Hh%Mm%Ss).txt
COMMAND="perl $RUN_PIPELINE -GBSSeqToTagDBPlugin -e $ENZYME -i $INPUT_DIR -db $DB -k $KEYFILE -kmerLength 64 -mnQS 0 -c 2 -endPlugin  2>&1 | tee $LOG"
echo $COMMAND >> $HISTORY
[ $DRYRUN == "run" ] && $COMMAND >> $LOG

# Step2: TagExportToFastqPlugin:
OUTPUT=$TEMPDIR'tagsForAlign.fa.gz'
LOG=$TEMPDIR'2_TagExportToFastqPlugin_'$(date +%Y%m%d-%Hh%Mm%Ss).txt
COMMAND="perl $RUN_PIPELINE -TagExportToFastqPlugin -db $DB -o $OUTPUT -endPlugin 2>&1 | tee $LOG"
echo $COMMAND >> $HISTORY
[ $DRYRUN == "run" ] && $COMMAND >> $LOG

# Step3: Alignment to the reference genome with BWA mem

LOG=$TEMPDIR'3_runBWA_mem_'$(date +%Y%m%d-%Hh%Mm%Ss).txt
MYSAM=$TEMPDIR'tagsForAlign.sam'
echo "$BWA mem $REFSEQ $OUTPUT 1> $MYSAM 2> $LOG"
[ $DRYRUN == "run" ] && $BWA mem $REFSEQ $OUTPUT 1> $MYSAM 2> $LOG


# Step4: SAMToGBSdbPlugin:
LOG=$TEMPDIR'4_SAMToGBSdbPlugin_'$(date +%Y%m%d-%Hh%Mm%Ss).txt
COMMAND="perl  $RUN_PIPELINE -SAMToGBSdbPlugin  -i $MYSAM -db $DB -endPlugin 2>&1 | tee $LOG"
echo $COMMAND >> $HISTORY
[ $DRYRUN == "run" ] && $COMMAND >> $LOG

# Step5: DiscoverySNPCallerPluginV2:
LOG=$TEMPDIR'5_DiscoverySNPCallerPluginV2_'$(date +%Y%m%d-%Hh%Mm%Ss).txt
COMMAND="perl  $RUN_PIPELINE -DiscoverySNPCallerPluginV2 -db $DB -sC chr01 -eC chr12 -mnMAF 0.01 -endPlugin 2>&1 | tee $LOG"
echo $COMMAND >>$HISTORY
[ $DRYRUN == "run" ] && $COMMAND >> $LOG

# Step6a: SNPQualityProfilerPlugin using subset of individuals:
#STATFILE=$TEMPDIR'SNPQualityStatsIBM.txt'
#LOG=$TEMPDIR'6a_SNPQualityProfilerPlugin_a_'$(date +%Y%m%d-%Hh%Mm%Ss).txt
#COMMAND="perl $RUN_PIPELINE -SNPQualityProfilerPlugin -db $DB -taxa $TAXA  -tname $TNAME -statFile $STATFILE -endPlugin 2>&1 | tee $LOG"
#echo $COMMAND >> $HISTORY
#$COMMAND >> $LOG

# Step6b: SNPQualityProfilerPlugin using all individuals:
STATFILE=$TEMPDIR'SNPQualityStats.txt'
LOG=$TEMPDIR'6b_SNPQualityProfilerPlugin_b_'$(date +%Y%m%d-%Hh%Mm%Ss).txt
COMMAND="perl $RUN_PIPELINE -SNPQualityProfilerPlugin -db $DB -statFile $STATFILE -endPlugin 2>&1 | tee $LOG"
echo $COMMAND >> $HISTORY
[ $DRYRUN == "run" ] && $COMMAND >> $LOG

# Making QSfile
QSFILE=$TEMPDIR'SNPQualityScoresAll.txt'
LOG=$TEMPDIR'addSNPQstat.txt'
#COMMAND="less $STATFILE | perl ./addSNPQStat.pl > $QSFILE | tee $LOG"
COMMAND1="echo 'CHROM\tPOS\tQUALITYSCORE' > $QSFILE"
COMMAND2="less SNPQualityStats.txt | awk 'BEGIN{OFS="\t"}{printf("%s\t%s\t10\n",$1,$2)}' >> $QSFILE | tee $LOG "
#echo $COMMAND >> $HISTORY
echo $COMMAND1 >> $HISTORY
echo $COMMAND2 >> $HISTORY
#$COMMAND >> $LOG
[ $DRYRUN == "run" ] && $COMMAND1 >> $LOG
[ $DRYRUN == "run" ] && $COMMAND2 >> $LOG

# Step7: UpdateSNPPositionQualityPlugin:
LOG=$TEMPDIR'7_UpdateSNPPositionQualityPlugin'$(date +%Y%m%d-%Hh%Mm%Ss).txt
COMMAND="perl $RUN_PIPELINE -UpdateSNPPositionQualityPlugin -db $DB -qsFile $QSFILE -endPlugin 2>&1 | tee $LOG"
echo $COMMAND >> $HISTORY
[ $DRYRUN == "run" ] && $COMMAND >> $LOG

# Step8: ProductionSNPCallerPluginV2:
LOG=$TEMPDIR'8_ProductionSNPCallerPluginV2'$(date +%Y%m%d-%Hh%Mm%Ss).txt
MYVCF=$TEMPDIR'TestGBSGenosMinQ1.vcf'
COMMAND="perl $RUN_PIPELINE -ProductionSNPCallerPluginV2 -db $DB -e $ENZYME -i $INPUT_DIR -k $KEYFILE  -o $MYVCF -endPlugin 2>&1 | tee $LOG"
echo $COMMAND >> $HISTORY
[ $DRYRUN == "run" ] && $COMMAND >> $LOG

# Step9: generate hapmap
LOG=$TEMPDIR'9_generateHapmap'$(date +%Y%m%d-%Hh%Mm%Ss).txt
MYHMP=$TEMPDIR'TestGBSGenosMinQ1'
COMMAND="perl $RUN_PIPELINE -Xmx5g -fork1 -vcf $MYVCF -export $MYHMP -exportType Hapmap -runfork1 2>&1 | tee $LOG"
echo $COMMAND >> $HISTORY
[ $DRYRUN == "run" ] && $COMMAND >> $LOG

# Step 10 VCFTOOLS THIN
THINVCF=$TEMPDIR'TestGBSGenosMinQ1_thin.vcf'
LOG=$TEMPDIR'10_vcftools_thin'$(date +%Y%m%d-%Hh%Mm%Ss).txt
COMMAND="$VCFTOOLS --vcf $MYVCF --thin 63 --recode --recode-INFO-all --out $THINVCF"
THIN_VCF_OUTPUT=$TEMPDIR'TestGBSGenosMinQ1_thin.vcf.recode.vcf'
echo $COMMAND >> $HISTORY
[ $DRYRUN == "run" ] && $COMMAND >> $LOG

# Step11: generate hapmap for thin
THINHMP=$TEMPDIR'TestGBSGenosMinQ1_thin'
LOG=$TEMPDIR'11_generateHapmap_thin'$(date +%Y%m%d-%Hh%Mm%Ss).txt
COMMAND="perl $RUN_PIPELINE -Xmx5g -fork1 -vcf $THIN_VCF_OUTPUT -export $THINHMP -exportType Hapmap -runfork1 2>&1 | tee $LOG"
echo $COMMAND >> $HISTORY
[ $DRYRUN == "run" ] && $COMMAND >> $LOG

# Step 12 CONVERT vcf for R
OUTPUT_TEXT="result_tassel5.txt"
THIN_VCF_OUTPUT=$TEMPDIR'TestGBSGenosMinQ1_thin.vcf.recode.vcf'
COMMAND="less $THIN_VCF_OUTPUT | perl vcf_ad.pl > $OUTPUT_TEXT"
echo $COMMAND >> $HISTORY
[ $DRYRUN == "run" ] && $COMMAND


