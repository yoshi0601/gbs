
PARENT1="tomohiro"
PARENT2="shoujusei"
LBIMPUTE="$HOME/git/LB-Impute/LB-Impute.jar"
PIPELINE="$HOME/tassel-5-standalone/run_pipeline.pl"

less $1 | perl prepareLBimpute.pl > new.vcf
java -Xmx2g -jar $LBIMPUTE -method impute -offspringimpute -f new.vcf -recombdist 20000000 -window 5 -o test.vcf -parents $PARENT1,$PARENT2

perl $PIPELINE -Xmx5g -fork1 -vcf test.vcf -export imputed -exportType Hapmap -runfork1

less imputed.hmp.txt | perl hmp_to_rqtl_cp.pl imputed.hmp.txt $PARENT1 $PARENT2 OUT

