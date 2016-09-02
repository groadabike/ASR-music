#!/usr/bin/env bash

. cmd.sh

stage=$1
nj=$2

# check whether run_tri1 is executed
if [ ! -d exp/tri1 ]; then
    echo "===== ERROR ===="
    echo "error, execute local/run_tri1.sh, first"
    exit 1;
fi

if [ $stage -le 3 ]; then

    echo
    echo "===== TRIPHONE MODEL with LDA + MLLT ====="
    echo
    echo "===== TRI2B ([LDA+MLLT]) TRAINING ====="
    echo

    steps/train_lda_mllt.sh --cmd "$train_cmd" \
     --splice-opts "--left-context=3 --right-context=3" \
     2500 15000 data/train data/lang exp/tri1_ali exp/tri2b

    echo
    echo "===== TRI2B ([LDA+MLLT]) ALIGNMENT ====="
    echo

    steps/align_si.sh --nj $nj --cmd "$train_cmd" --use-graphs true  \
     data/train data/lang exp/tri2b exp/tri2b_ali
fi