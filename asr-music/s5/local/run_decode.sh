#!/usr/bin/env bash

. cmd.sh

stage=$1
nj=$2
mail=$3
email=$4

if [ $stage -le 5 ]; then
    if [ ! -d exp/mono/decode ]; then
        echo
        echo "===== MONO DECODING ====="
        echo

        utils/mkgraph.sh --mono data/lang exp/mono exp/mono/graph || exit 1

        steps/decode.sh --config conf/decode.config --nj $nj --cmd "$decode_cmd" \
        --scoring-opts "--min-lmwt 10 --max-lmwt 20" --num-threads 3 \
         exp/mono/graph data/test exp/mono/decode

        if [ $mail -eq 1 ]; then
            echo
            echo "===== MONO CLEANUP ====="
            echo

            # deprecated code
            #
            # steps/cleanup/find_bad_utts.sh --nj $nj --cmd "$train_cmd" \
            # data/train data/lang  exp/mono_ali exp/mono_cleanup
            #
            # Changed by: (Expected to run over SAT training)

            steps/cleanup/clean_and_segment_data.sh --nj $nj --cmd "$train_cmd"  \
            data/train data/lang  exp/mono_ali exp/mono_cleanup data/mono_train_cleaned

            filename=${PWD##*/}

            echo "Mono Cleanup of $filename" |  mail -s "Mono Cleanup of $filename" \
             -a /home/acp15gr/logs/log_${filename}.txt \
             -a /data/acp15gr/kaldi/egs/ASR-music/${filename}/exp/mono_cleanup/all_info.sorted.txt \
             -a /data/acp15gr/kaldi/egs/ASR-music/${filename}/exp/mono_cleanup/analysis/ops_details.txt \
             -a /data/acp15gr/kaldi/egs/ASR-music/${filename}/exp/mono_cleanup/analysis/per_spk_details.txt \
             -a /data/acp15gr/kaldi/egs/ASR-music/${filename}/exp/mono_cleanup/analysis/per_utt_details.txt \
             $email
        fi
    fi


    if [ ! -d exp/tri1/decode ]; then

        echo
        echo "===== TRI1 DECODING ====="
        echo

        utils/mkgraph.sh data/lang exp/tri1 exp/tri1/graph || exit 1

        steps/decode.sh --config conf/decode.config --nj $nj --cmd "$decode_cmd" \
        --scoring-opts "--min-lmwt 10 --max-lmwt 25" --num-threads 3 \
         exp/tri1/graph data/test exp/tri1/decode

        if [ $mail -eq 1 ]; then
            echo
            echo "===== TRI1 CLEANUP ====="
            echo

            # Deprecated Code
            #
            #steps/cleanup/find_bad_utts.sh --nj $nj --cmd "$train_cmd" \
            # data/train data/lang  exp/tri1_ali exp/tri1_cleanup
            #
            # Changed by: (Expected to run over SAT training)
            steps/cleanup/clean_and_segment_data.sh --nj $nj --cmd "$train_cmd"  \
            data/train data/lang  exp/tri1_ali exp/tri1_cleanup data/tri1_train_cleaned

            filename=${PWD##*/}

            echo "Tri1 Cleanup of $filename" |  mail -s "Tri1 Cleanup of $filename" \
             -a /home/acp15gr/logs/log_${filename}.txt \
             -a /data/acp15gr/kaldi/egs/ASR-music/${filename}/exp/tri1_cleanup/all_info.sorted.txt \
             -a /data/acp15gr/kaldi/egs/ASR-music/${filename}/exp/tri1_cleanup/analysis/ops_details.txt \
             -a /data/acp15gr/kaldi/egs/ASR-music/${filename}/exp/tri1_cleanup/analysis/per_spk_details.txt \
             -a /data/acp15gr/kaldi/egs/ASR-music/${filename}/exp/tri1_cleanup/analysis/per_utt_details.txt \
             $email
        fi
    fi

    if [ ! -d exp/tri2b/decode ]; then

        echo
        echo "===== TRI2B ([LDA+MLLT]) DECODING ====="
        echo

        utils/mkgraph.sh data/lang exp/tri2b exp/tri2b/graph

        steps/decode.sh --config conf/decode.config --nj $nj --cmd "$decode_cmd" \
        --scoring-opts "--min-lmwt 10 --max-lmwt 25" --num-threads 3 \
         exp/tri2b/graph data/test exp/tri2b/decode

        if [ $mail -eq 1 ]; then
            echo
            echo "===== TRI2B ([LDA+MLLT]) CLEANUP ====="
            echo

            # Deprecated Code
            #
            # steps/cleanup/find_bad_utts.sh --nj $nj --cmd "$train_cmd" \
            #  data/train data/lang  exp/tri2b_ali exp/tri2b_cleanup
            #
            # Changed by: (Expected to run over SAT training)
            steps/cleanup/clean_and_segment_data.sh --nj $nj --cmd "$train_cmd"  \
                data/train data/lang  exp/tri2b_ali exp/tri2b_cleanup data/tri2b_train_cleaned

            filename=${PWD##*/}

            echo "Tri2b Cleanup of $filename" |  mail -s "Tri2b Cleanup of $filename" \
             -a /home/acp15gr/logs/log_${filename}.txt \
             -a /data/acp15gr/kaldi/egs/ASR-music/${filename}/exp/tri2a_cleanup/all_info.sorted.txt \
             -a /data/acp15gr/kaldi/egs/ASR-music/${filename}/exp/tri2b_cleanup/analysis/ops_details.txt \
             -a /data/acp15gr/kaldi/egs/ASR-music/${filename}/exp/tri2b_cleanup/analysis/per_spk_details.txt \
             -a /data/acp15gr/kaldi/egs/ASR-music/${filename}/exp/tri2b_cleanup/analysis/per_utt_details.txt \
             $email
        fi
    fi

fi
