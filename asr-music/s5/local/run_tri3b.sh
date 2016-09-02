#!/usr/bin/env bash

. cmd.sh

stage=$1
nj=$2
mail=$3
email=$4


# check whether run_tri2b is executed
if [ ! -d exp/tri2b ]; then
    echo "===== ERROR ===="
    echo "error, execute local/run_tri2b.sh, first"
    exit 1;
fi

if [ $stage -le 4 ]; then

    echo
    echo "===== TRIPHONE MODEL with SAT ====="
    echo
    echo "===== TRI3B LDA+MLLT+SAT, and decode ====="
    echo

    steps/train_sat.sh 2500 15000 data/train data/lang exp/tri2b_ali exp/tri3b



    echo
    echo "===== TRI3B LDA+MLLT+SAT DECODING ====="
    echo

    utils/mkgraph.sh data/lang exp/tri3b exp/tri3b/graph

    steps/decode_fmllr.sh --config conf/decode.config --nj $nj \
     --num-threads 3 --cmd "$decode_cmd"  \
     --scoring-opts "--min-lmwt 10 --max-lmwt 25" \
      exp/tri3b/graph data/test exp/tri3b/decode

    steps/decode_fmllr.sh --config conf/decode.config --nj $nj \
         --num-threads 3 --cmd "$decode_cmd"  \
         --scoring-opts "--min-lmwt 15 --max-lmwt 25" \
          exp/tri3b/graph data/test_final exp/tri3b/decode_final

    steps/decode_fmllr.sh --config conf/decode.config --nj $nj \
         --num-threads 3 --cmd "$decode_cmd"  \
         --scoring-opts "--min-lmwt 15 --max-lmwt 25" \
          exp/tri3b/graph data/test_piano exp/tri3b/decode_piano

    if [ $mail -eq 1 ]; then
        echo
        echo "===== TRI3B LDA+MLLT+SAT CLEANUP ====="
        echo

        # Deprecated Code
        #
        # steps/cleanup/find_bad_utts.sh --nj $nj --cmd "$train_cmd" \
        #  data/train data/lang  exp/tri3b_ali exp/tri3b_cleanup
        #
        # Changed by: (Expected to run over SAT training)
        steps/cleanup/clean_and_segment_data.sh --nj $nj --cmd "$train_cmd"  \
            data/train data/lang  exp/tri3b_ali exp/tri3b_cleanup data/tri3b_train_cleaned

        filename=${PWD##*/}

        echo "Tri3b Cleanup of $filename" |  mail -s "Tri3b Cleanup of $filename" \
         -a /home/acp15gr/logs/log_${filename}.txt \
         -a /data/acp15gr/kaldi/egs/ASR-music/${filename}/exp/tri3b_cleanup/all_info.sorted.txt \
         -a /data/acp15gr/kaldi/egs/ASR-music/${filename}/exp/tri3b_cleanup/analysis/ops_details.txt \
         -a /data/acp15gr/kaldi/egs/ASR-music/${filename}/exp/tri3b_cleanup/analysis/per_spk_details.txt \
         -a /data/acp15gr/kaldi/egs/ASR-music/${filename}/exp/tri3b_cleanup/analysis/per_utt_details.txt \
         $email
    fi


    echo
    echo "===== TRI3B LDA+MLLT+SAT ALIGNMENT ====="
    echo

    steps/align_fmllr.sh --nj $nj --cmd "$train_cmd"  \
     data/train data/lang exp/tri3b exp/tri3b_ali
fi