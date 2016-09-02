#!/bin/bash

. ./cmd.sh

stage=$1
nj=$2
lm_order=$3
feature=$4

fullhost=`hostname -f`

if [ $stage -le 0 ]; then

    # Removing previously created data (from last run.sh execution)
    rm -rf exp mfcc data/train/spk2utt data/train/cmvn.scp data/train/feats.scp data/train/split* data/test/spk2utt data/test/cmvn.scp data/test/feats.scp data/test/split* data/local/lang data/lang data/local/tmp data/local/dict/lexiconp.txt

    echo
    echo "===== PREPARING ACOUSTIC DATA ====="
    echo

    # Needs to be prepared by hand (or using self written scripts):
    #
    # spk2gender  [<speaker-id> <gender>]
    # wav.scp     [<uterranceID> <full_path_to_audio_file>]
    # text        [<uterranceID> <text_transcription>]
    # utt2spk     [<uterranceID> <speakerID>]
    # corpus.txt  [<text_transcription>]

    echo "Creating spk2gender..."
	echo "Creating wav.scp..."
	echo "Creating text..."
	echo "Creating utt2spk..."

    local/recipe_data_files.py input $LYRICS_ROOT/annotation .
    #local/create_corpus.py $lyrics/lmodel/lyrics_out.txt $lyrics/lmodel/lexicon.txt $lyrics/lmodel/corpus.txt

    echo
    echo "===== FEATURES EXTRACTION ====="
    echo


    # Making feats.scp files

    for x in train test test_final test_piano; do

        # Making spk2utt files
        utils/utt2spk_to_spk2utt.pl data/$x/utt2spk > data/$x/spk2utt

        utils/validate_data_dir.sh data/$x     # script for checking if prepared data is all right
        utils/fix_data_dir.sh data/$x          # tool for data sorting if something goes wrong above

        if [ ${feature} == "mfcc" ]; then
            mfccdir=mfcc
            steps/make_mfcc.sh --nj $nj --cmd "$train_cmd" data/$x exp/make_mfcc/$x $mfccdir
        elif [ ${feature} == "plp" ]; then
            mfccdir=plp
            steps/make_plp.sh --nj $nj --cmd "$train_cmd" data/$x exp/make_mfcc/$x $mfccdir
        fi

        # Making cmvn.scp files
        steps/compute_cmvn_stats.sh data/$x exp/make_mfcc/$x $mfccdir
    done

    echo
    echo "===== PREPARING LANGUAGE DATA ====="
    echo

    # Needs to be prepared by hand (or using self written scripts):
    #
    # lexicon.txt            [<word> <phone 1> <phone 2> ...]
    # nonsilence_phones.txt  [<phone>]
    # silence_phones.txt     [<phone>]
    # optional_silence.txt   [<phone>]

    # Preparing language data
    utils/prepare_lang.sh data/local/dict "<UNK>" data/local/lang data/lang

    echo
    echo "===== LANGUAGE MODEL CREATION ====="
    echo "===== MAKING lm.arpa ====="
    echo

    loc=`which ngram-count`;
    if [ -z $loc ]; then
         if uname -a | grep 64 >/dev/null; then
            sdir=$KALDI_ROOT/tools/srilm/bin/i686-m64
        else
                sdir=$KALDI_ROOT/tools/srilm/bin/i686
          fi
          if [ -f $sdir/ngram-count ]; then
                echo "Using SRILM language modelling tool from $sdir"
                export PATH=$PATH:$sdir
          else
                echo "SRILM toolkit is probably not installed.
                  Instructions: tools/install_srilm.sh"
                exit 1
          fi
    fi

    local=data/local
    mkdir $local/tmp
    ngram-count -order $lm_order -write-vocab $local/tmp/vocab-full.txt -wbdiscount -text $local/corpus.txt -lm $local/tmp/lm.arpa

    echo
    echo "===== MAKING G.fst ====="
    echo

    lang=data/lang
    cat $local/tmp/lm.arpa | arpa2fst - | fstprint | utils/eps2disambig.pl | utils/s2eps.pl | fstcompile --isymbols=$lang/words.txt --osymbols=$lang/words.txt --keep_isymbols=false --keep_osymbols=false | fstrmepsilon | fstarcsort --sort_type=ilabel > $lang/G.fst

fi