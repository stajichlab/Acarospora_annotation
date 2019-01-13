#!/bin/bash
#SBATCH -p short --ntasks 2 --nodes 1 --mem 8G --out logs/annotate_combine.%a.log -J annotcombine
module unload python
module unload perl
module unload perl
module load perl/5.24.0
module load miniconda2
module load funannotate
export AUGUSTUS_CONFIG_PATH=/bigdata/stajichlab/shared/pkg/augustus/3.3/config
#TEMP=/scratch/$USER
#mkdir -p $TEMP
if [ -z $SLURM_JOB_ID ]; then
	SLURM_JOB_ID=$$
fi
CPU=1
if [ $SLURM_CPUS_ON_NODE ]; then
    CPU=$SLURM_CPUS_ON_NODE
fi

INDIR=genomes
OUTDIR=annotate
BUSCO_DIR=/srv/projects/db/BUSCO/v9
SBTFOLDER=sbt
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
 if [ ! -f $INDIR/$name.masked.fasta ]; then
	echo "No genome for $INDIR/$name.masked.fasta yet - run 00_mash.sh $N"
	exit
 fi
 ANNOTDIR=$(realpath $OUTDIR/$name)
 SBTFILE=$(realpath $SBTFOLDER/$SBT)
 mkdir $name.annotate.$SLURM_JOB_ID
 pushd $name.annotate.$SLURM_JOB_ID
 echo "funannotate annotate --busco_db $BUSCO_DIR/$BUSCO -i $ANNOTDIR --species "$Species" --strain "$strain" --cpus $CPU --sbt $SBTFILE"
 funannotate annotate --busco_db $BUSCO_DIR/$BUSCO -i $ANNOTDIR --species "$Species" --strain "$strain" --cpus $CPU --sbt $SBTFILE
 mv funannotate-annotate.log ../logs/annotate.$SLURM_JOB_ID.log
 popd $name.annotate.$SLURM_JOB_ID
done
