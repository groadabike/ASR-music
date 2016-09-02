#!/bin/bash


. ./path.sh
. ./cmd.sh

nj=$1
mail=$2  # Not used in these script
email=$3 # Not used in these script
use_gpu="no"

. utils/parse_options.sh || exit 1;


# check whether run_tri3b is executed
if [ ! -d exp/tri3b ]; then
  echo "error, execute local/run_tri3b.sh, first"
  exit 1;
fi

if [ $stage -le 6 ]; then
    gmmdir=exp/tri3b
    data_fmllr=data-fmllr-tri3b
    mkdir -p $data_fmllr

    echo
    echo "===== Creating FMMML Features ====="
    echo
    if [ ! -e $data_fmllr/test ]; then

        # test
        dir=$data_fmllr/test
        steps/nnet/make_fmllr_feats.sh --nj $nj --cmd "$train_cmd" \
        --transform-dir $gmmdir/decode $dir data/test $gmmdir $dir/log $dir/data

        echo

        dir=$data_fmllr/test_final
        steps/nnet/make_fmllr_feats.sh --nj $nj --cmd "$train_cmd" \
        --transform-dir $gmmdir/decode_final $dir data/test_final $gmmdir $dir/log $dir/data

        echo

        dir=$data_fmllr/test_piano
        steps/nnet/make_fmllr_feats.sh --nj $nj --cmd "$train_cmd" \
        --transform-dir $gmmdir/decode_piano $dir data/test_piano $gmmdir $dir/log $dir/data

        echo

        # train
        dir=$data_fmllr/train
        steps/nnet/make_fmllr_feats.sh --nj $nj --cmd "$train_cmd" \
        --transform-dir ${gmmdir}_ali \
        $dir data/train $gmmdir $dir/log $dir/data

         # split the data : 90% train 10% cross-validation (held-out)
        utils/subset_data_dir_tr_cv.sh $dir ${dir}_tr90 ${dir}_cv10

    fi

    echo
    echo "===== Pretraining DNN ====="
    echo

    dir=exp/dnn5b_pretrain-dbn
    if [ ! -f $dir/final.feature_transform ]; then
        # pre-train dnn
    (tail --pid=$$ -F $dir/log/pretrain_dbn.log 2>/dev/null)& # forward log
        $long_cuda_cmd $dir/log/pretrain_dbn.log \
         steps/nnet/pretrain_dbn.sh --nn-depth 7 --rbm-iter 20 $data_fmllr/train $dir
    fi

    echo
    echo "===== Training DNN ====="
    echo
    # train dnn
    dir=exp/dnn5b_pretrain-dbn_dnn
    ali=${gmmdir}_ali
    feature_transform=exp/dnn5b_pretrain-dbn/final.feature_transform
    dbn=exp/dnn5b_pretrain-dbn/7.dbn
    (tail --pid=$$ -F $dir/log/train_nnet.log 2>/dev/null)& # forward log
    if [ ! -f $dir/final.feature_transform ]; then
        $long_cuda_cmd $dir/log/train_nnet.log \
         steps/nnet/train.sh --feature-transform $feature_transform \
         --dbn $dbn --hid-layers 0 --learn-rate 0.008 \
         $data_fmllr/train_tr90 $data_fmllr/train_cv10 data/lang $ali $ali $dir
    fi

    echo
    echo "===== Decoding DNN ====="
    echo

    if [ ! -d $dir/decode/scoring_kaldi ]; then
     # Decode (reuse HCLG graph)
         for testset in test test_final test_piano; do
            steps/nnet/decode.sh --nj $nj --cmd "$decode_cmd" --acwt 0.1 \
             --config conf/decode_dnn.config  \
             --scoring_opts "--min-lmwt 10 --max-lmwt 20" \
             --use_gpu $use_gpu --num-threads 3 \
             $gmmdir/graph $data_fmllr/$testset $dir/decode
         done
    fi

    echo
    echo "===== Aligning DNN ====="
    echo
    # Sequence training using sMBR criterion, we do Stochastic-GD
    # with per-utterance updates. We use usually good acwt 0.1
    # Lattices are re-generated after 1st epoch, to get faster convergence.
    dir=exp/dnn5b_pretrain-dbn_dnn_smbr
    srcdir=exp/dnn5b_pretrain-dbn_dnn
    acwt=0.1

    if [ ! -f ${srcdir}_ali/final.mdl ]; then
        steps/nnet/align.sh --nj $nj --cmd "$train_cmd" --use_gpu $use_gpu \
            $data_fmllr/train data/lang $srcdir ${srcdir}_ali
    fi

    echo
    echo "===== Making Denlats DNN ====="
    echo

    if [ ! -f ${srcdir}_denlats/final.mdl ]; then
        steps/nnet/make_denlats.sh --nj $nj --cmd "$decode_cmd" --config conf/decode_dnn.config \
            --use-gpu $use_gpu --parallel_opts "--num-threads 3" \
            --acwt $acwt $data_fmllr/train data/lang $srcdir ${srcdir}_denlats
    fi

    echo
    echo "===== Training DNN - sMBR ====="
    echo

    if [ ! -d $dir ]; then
         # Re-train the DNN by 6 iterations of sMBR
        steps/nnet/train_mpe.sh --cmd "$long_cuda_cmd" --num-iters 6 --acwt $acwt --do-smbr true --skip_cuda_check true \
          $data_fmllr/train data/lang $srcdir ${srcdir}_ali ${srcdir}_denlats $dir
    fi

    for testset in test test_final test_piano; do
         # Decode
        for ITER in 6 3 1; do
            if [ ! -d $dir/decode_it${ITER}/scoring_kaldi ];then
            echo
            echo "===== Decoding Iteration $ITER DNN ====="
            echo
                    steps/nnet/decode.sh --nj $nj --cmd "$decode_cmd" --config conf/decode_dnn.config \
                      --scoring_opts "--min-lmwt 10 --max-lmwt 20" \
                      --use_gpu $use_gpu --num-threads 3 --nnet $dir/${ITER}.nnet --acwt $acwt \
                      $gmmdir/graph $data_fmllr/$testset $dir/decode_it${ITER}
            fi
        done
    done

fi
