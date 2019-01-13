#!/bin/bash
#SBATCH -p batch --time 1-0:00:00 --ntasks 32 --nodes 1 --mem 48GG --out logs/iprscan.%a.log -J iprscan 

module load funannotate
module load iprscan
SAMPFILE=genomes.csv

if [ -z $SLURM_JOB_ID ]; then
	SLURM_JOB_ID=$$
fi
CPU=1
if [ $SLURM_CPUS_ON_NODE ]; then
    CPU=$SLURM_CPUS_ON_NODE
fi

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

OUTDIR=annotate
IFS=,
tail -n +2 $SAMPFILE | sed -n ${N}p | while read Species Strain Phyla SubPhyla Prefix Transcripts BUSCO SBT
do
 species=$(echo "$Species" | perl -p -e 'chomp; s/\s+/_/g')
 strain=$(echo "$Strain" | perl -p -e 'chomp; s/\s+/_/g')
 name=${species}_${strain}
 ANNOTDIR=$(realpath $OUTDIR/$name)

 XML=$ANNOTDIR/annotate_misc/iprscan.xml
 if [ ! -f $XML ]; then
    funannotate iprscan -i $ANNOTDIR -o $XML -m local -c $CPU  --iprscan_path $(which interproscan.sh)
 fi
done
