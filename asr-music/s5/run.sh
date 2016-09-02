#!/bin/bash

fullhost=`hostname -f`

# If on the Iceberg cluster...
if [[ ${fullhost} == *"iceberg.shef.ac.uk" ]]; then
  module load apps/python/conda
  source activate myexperiment
  module load compilers/gcc/4.9.2
  module add libs/cuda/7.5.18
fi

. ./path.sh || exit 1
. ./cmd.sh || exit 1

nj=6            # number of parallel jobs
lm_order=2      # language model's order (n-gram quantity)
feature="mfcc"  # (plp|mfcc)

# Stage control parameters
# 0 = from beginning
# 1 = from mono
# 2 = from tri1
# 3 = from tri2b
# 4 = from tii3b
# 5 = from decode GMM
# 6 = from DNN
stage=0

# Run Cleanup
mail=0      # run cleanup and send email (1 = true|0 = false)
email="groadabike1@sheffield.ac.uk"  # if mail=1 the results will send to this email

filename=${PWD##*/}

local=data/local
echo
echo "===== STARTING PROCESS $filename =====" | tr [a-z] [A-Z]
echo

[ ! -L "wav" ] && ln -s $DATA_ROOT

echo "Using steps and utils from wsj recipe"

[ ! -L "steps" ] && ln -s $KALDI_ROOT/egs/wsj/s5/steps
[ ! -L "utils" ] && ln -s $KALDI_ROOT/egs/wsj/s5/utils

# Link score
yes | cp -a steps/score_kaldi.sh local/score.sh
chmod 755 local/score.sh

utils/parse_options.sh || exit 1
[[ $# -ge 1 ]] && { echo "Wrong arguments!"; exit 1; } 

# Prepare Acoustic Files, Features and Language Model

local/prepare_am_feature_lm.sh $stage=$stage $nj $lm_order $feature

# Start to run different models from MONO to DNN

local/run_mono.sh  $stage=$stage $nj

local/run_tri1.sh  $stage=$stage $nj

local/run_tri2b.sh  $stage=$stage $nj

local/run_tri3b.sh  $stage=$stage $nj $mail $email

echo
echo "===== DECODE ALL MODELS ====="
echo

local/run_decode.sh  $stage=$stage  $nj $mail $email

echo
echo "===== SCORE GMMs ====="
echo

for x in exp/*/decode*; do [ -d $x ] && grep WER $x/wer_* | utils/best_wer.sh; done

echo
echo "===== RUN DNN ====="
echo

local/run_dnn.sh  $stage=$stage  $nj $mail $email

#score

echo
echo "===== SCORES ====="
echo

for x in exp/*/decode*; do [ -d $x ] && grep WER $x/wer_* | utils/best_wer.sh; done

echo
echo "===== $filename script is finished ====="
echo

exit 1