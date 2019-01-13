#!/bin/bash
#SBATCH -p batch --time 8:00:00 --ntasks 2 --nodes 1 --mem 12G --out logs/phobius.%a.log -J phobious
module load phobius
if [ -z $SLURM_JOB_ID ]; then
	SLURM_JOB_ID=$$
fi
CPU=1
if [ $SLURM_CPUS_ON_NODE ]; then
    CPU=$SLURM_CPUS_ON_NODE
fi

OUTDIR=annotate
SAMPFILE=genomes.csv
EMAIL=jasonstajich.phd@gmail.com

N=${SLURM_ARRAY_TASK_ID}
if [ ! $N ]; then
    N=$1
    if [ ! $N ]; then
        echo "need to provide a number by --array or cmdline"
        exit
    fi
fi
MAX=`wc -l $SAMPFILE | awk '{print $1}'`

if [ "$N" -gt "$MAX" ]; then
    echo "$N is too big, only $MAX lines in $SAMPFILE"
    exit
fi
IFS=,
tail -n +2 $SAMPFILE | sed -n ${N}p | while read Species Strain Phyla SubPhyla Prefix Transcripts BUSCO SBT
do
 species=$(echo "$Species" | perl -p -e 'chomp; s/\s+/_/g')
 strain=$(echo "$Strain" | perl -p -e 'chomp; s/\s+/_/g')
 name=${species}_${strain}
 ANNOTDIR=$(realpath $OUTDIR/$name)
 phobius -short $ANNOTDIR/predict_results/$name.proteins.fa > $ANNOTDIR/annotate_misc/$name.phobius.out
done
