#!/usr/bin/env bash

. cmd.sh

stage=$1
nj=$2

if [ $stage -le 1 ]; then
    echo
    echo "===== MONOPHONE MODEL ====="
    echo
    echo "===== MONO TRAINING ====="
    echo

    steps/train_mono.sh --boost-silence 1.25 --nj $nj --cmd "$train_cmd" \
     data/train data/lang exp/mono  || exit 1

    echo
    echo "===== MONO ALIGNMENT ====="
    echo

    steps/align_si.sh --boost-silence 1.25 --nj $nj --cmd "$train_cmd" \
     data/train data/lang exp/mono exp/mono_ali || exit 1

    echo
    echo "===== MONOPHONE END ====="
    echo
fi