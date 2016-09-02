fullhost=`hostname -f`

# If on the Iceberg cluster...
if [[ ${fullhost} == *"iceberg.shef.ac.uk" ]]; then
	export KALDI_ROOT="/data/acp15gr/kaldi" 
	export DATA_ROOT="/data/acp15gr/wav/"
	export LYRICS_ROOT="/home/acp15gr/lyrics"
else
	export KALDI_ROOT=`pwd`/../../..
	export DATA_ROOT="/home/gerardo/ARS-Music/wav/"
	export LYRICS_ROOT="/home/gerardo/ARS-Music/lyrics"
fi

[ -f $KALDI_ROOT/tools/env.sh ] && . $KALDI_ROOT/tools/env.sh

# Setting paths to useful tools
export PATH=$PWD/utils/:$KALDI_ROOT/src/bin:$KALDI_ROOT/src/lmbin:$KALDI_ROOT/tools/openfst/bin:$KALDI_ROOT/src/fstbin/:$KALDI_ROOT/src/gmmbin/:$KALDI_ROOT/src/featbin/:$KALDI_ROOT/src/lm/:$KALDI_ROOT/src/sgmmbin/:$KALDI_ROOT/tools/liblbfgs-1.10/lib/.libs/:/usr/local/lib/:usr/local/lib/:$KALDI_ROOT/src/sgmm2bin/:/usr/include/arpa/:$KALDI_ROOT/src/fgmmbin/:$KALDI_ROOT/src/latbin/:$PWD:$PATH

export PATH=$PATH:$KALDI_ROOT/src/nnetbin

# Variable that stores path to MITLM library
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$(pwd)/tools/mitlm-svn/lib

# Variable needed for proper data sorting
export LC_ALL=C