#!/usr/bin/env bash

. cmd.sh

stage=$1
nj=$2

# check whether run_mono is executed
if [ ! -d exp/mono ]; then
    echo "===== ERROR ===="
    echo "error, execute local/run_mono.sh, first"
    exit 1;
fi

if [ $stage -le 2 ]; then
    echo
    echo "===== TRIPHONE MODEL (delta, delta+delta) ====="
    echo
    echo "===== TRI1 TRAINING ====="
    echo

    steps/train_deltas.sh --boost-silence 1.25 --cmd "$train_cmd" 2000 11000 \
     data/train data/lang exp/mono_ali exp/tri1 || exit 1


    echo
    echo "===== TRI1 ALIGNMENT ====="
    echo

    steps/align_si.sh --nj $nj --cmd "$train_cmd" --use-graphs true \
     data/train data/lang exp/tri1 exp/tri1_ali || exit 1

fi