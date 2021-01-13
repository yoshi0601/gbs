
INPUTVCF=$1
PARENT1=$2
PARENT2=$3
LBIMPUTE="$HOME/git/LB-Impute/LB-Impute.jar"
PIPELINE="$HOME/tassel-5-standalone/run_pipeline.pl"
GBSTOOLDIR="$HOME/git/gbs"

less ${INPUTVCF} | perl $GBSTOOLDIR/prepareLBimpute.pl > new.vcf
java -Xmx2g -jar $LBIMPUTE -method impute -offspringimpute -f new.vcf -recombdist 20000000 -window 5 -o test.vcf -parents $PARENT1,$PARENT2

perl $PIPELINE -Xmx5g -fork1 -vcf test.vcf -export imputed -exportType Hapmap -runfork1

less imputed.hmp.txt | perl $GBSTOOLDIR/hmp_to_rqtl_cp.pl imputed.hmp.txt $PARENT1 $PARENT2 OUT

