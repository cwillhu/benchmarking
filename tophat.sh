#!/bin/bash

#Run TopHat on a variety of samples, capturing stdout/stderr and recording benchmarking statistics via time function

set -eu

Projdir=/home/cwill/example
Indir=$Projdir/fastq
Outdir=$Projdir/tophat
Samples=$(cat $Projdir/Samples.txt)
Reference=/odyssey/informatics/genomes/geoFor1/annotation  

Numthreads=10
Numproc=$((48/Numthreads)) #48 cpus on sandy

module load centos6/tophat-2.0.11.Linux_x86_64
mkdir -p $Outdir
cd $Indir

run_tophat () {
  Sample=$1
  ReferenceDir=$2
  Outdir=$3
  Numthreads=$4

  mkdir -p $Outdir/$Sample
  echo -e "\nRunning Tophat on $Sample..."
  {
    command time -f "$Sample %U %S %E %e %P %M $Numthreads" -o $Outdir/.temp.$Sample \
      tophat --output-dir $Outdir/$Sample \
         --num-threads $Numthreads \
         $Reference/xenoRefMrna \
         $Sample.R1.fastq $Sample.R2.fastq
  } 2>&1 | tee -a $Outdir/out.$Sample.txt
}

export -f run_tophat 
printf "%s\n" $Samples | xargs -P $Numproc -I{} bash -euc 'run_tophat "$@"' run_tophat {} $Reference $Outdir $Numthreads
echo -e "\nDone."

#gather benchmarking stats for all jobs
echo "Sample UserCPUsec SysCPUsec ElapsedTime ElapsedSec PercCPU MaxRSS_kB Numthreads" > $Outdir/stats.tophat
cat $Outdir/.temp.* >> $Outdir/stats.tophat
rm $Outdir/.temp.*
