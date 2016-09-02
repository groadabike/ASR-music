#!/usr/bin/env bash

# "queue.pl" uses qsub.  The options to it are
# options to qsub.  If you have GridEngine installed,
# change this to a queue you have access to.
# Otherwise, use "run.pl", which will run jobs locally
# (make sure your --num-jobs options are no more than
# the number of cpus on your machine.

# Run locally:
export long_cmd="run.pl"
export train_cmd="run.pl"
export decode_cmd="run.pl"
export cuda_cmd="run.pl"
export long_cuda_cmd="run.pl"
export parallel_opts=""
export jq_cmd="jq"

fullhost=`hostname -f`

# If on the Iceberg cluster...
if [[ ${fullhost} == *"iceberg.shef.ac.uk" ]]; then
#  module load apps/python/conda
#  source activate myexperiment
#
#  module load compilers/gcc/4.9.2
  export long_cmd="queue.pl -l mem=8G,rmem=6G,h_rt=48:00:00 -j y"
  export train_cmd="queue.pl -l mem=8G -j y"
  export decode_cmd="queue.pl -l mem=8G -j y"
  export cuda_cmd="queue.pl --gpu 1 -j y"
  export long_cuda_cmd="queue.pl --gpu 1 -l mem=24G,rmem=20G,h_rt=48:00:00 -j y"
  export parallel_opts="-pe openmp 4"
  export jq_cmd="local/jq-linux64"
else
  export long_cmd="run.pl"
  export train_cmd="run.pl"
  export decode_cmd="run.pl"
  export cuda_cmd="run.pl"
  export long_cuda_cmd="run.pl"
  export parallel_opts=""
  export jq_cmd="jq"

fi
