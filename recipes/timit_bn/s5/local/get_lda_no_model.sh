#!/bin/bash

# Copyright 2012 Johns Hopkins University (Author: Daniel Povey).  Apache 2.0.
# This script, which will generally be called from other neural-net training
# scripts, extracts the training examples used to train the neural net (and also
# the validation examples used for diagnostics), and puts them in separate archives.

# Begin configuration section.
cmd=run.pl


stage=-1

nj=4
feat_type=raw

splice_width=5 # meaning +- 4 frames on each side for second LDA
left_context= # left context for second LDA
right_context= # right context for second LDA
rand_prune=4.0 # Relates to a speedup we do for LDA.
within_class_factor=0.0001 # This affects the scaling of the transform rows...
                           # sorry for no explanation, you'll have to see the code.
transform_dir=     # If supplied, overrides alidir
num_feats=10000 # maximum number of feature files to use.  Beyond a certain point it just
                # gets silly to use more data.
lda_dim=  # This defaults to no dimension reduction.
online_ivector_dir=
ivector_randomize_prob=0.0 # if >0.0, randomizes iVectors during training with
                           # this prob per iVector.
ivector_dir=
cmvn_opts=  # allows you to specify options for CMVN, if feature type is not lda.

output=lda

echo "$0 $@"  # Print the command line for logging

if [ -f path.sh ]; then . ./path.sh; fi
. parse_options.sh || exit 1;


if [ $# != 4 ]; then
  echo "Usage: steps/nnet2/get_lda.sh [opts] <train/test> <post> <num-of-states> <lda-out-dim>"
  echo " e.g.: steps/nnet2/get_lda.sh train *.post exp/lda 300"
  echo " As well as extracting the examples, this script will also do the LDA computation,"
  echo " if --est-lda=true (default:true)"
  echo ""
  echo "Main options (for others, see top of script file)"
  echo "  --config <config-file>                           # config file containing options"
  echo "  --cmd (utils/run.pl|utils/queue.pl <queue opts>) # how to run jobs."
  echo "  --splice-width <width|4>                         # Number of frames on each side to append for feature input"
  echo "                                                   # (note: we splice processed, typically 40-dimensional frames"
  echo "  --left-context <width;4>                         # Number of frames on left side to append for feature input, overrides splice-width"
  echo "  --right-context <width;4>                        # Number of frames on right side to append for feature input, overrides splice-width"
  echo "  --stage <stage|0>                                # Used to run a partially-completed training process from somewhere in"
  echo "                                                   # the middle."
  echo "  --online-vector-dir <dir|none>                   # Directory produced by"
  echo "                                                   # steps/online/nnet2/extract_ivectors_online.sh"
  exit 1;
fi



root=$(pwd -P)

datadir=./data
data=$root/$datadir/$1
post=$2
#dir=$3
#ldadir=$4
num_state=$3
ldadim=$4

posttype=$(basename $post .post)
#posttype=1best_mfcc_s3_g2_sil_10_states
cmvndir=$root/cmvn_lda_${posttype}
datatype=$1
dir=exp/lda/dim_${ldadim}/$posttype
ldadir=$root/LDA/dim_${ldadim}/$posttype/$datatype

stage=$stage
[ -z "$left_context" ] && left_context=$splice_width
[ -z "$right_context" ] && right_context=$splice_width


# Set some variables.

# in this dir we'll have just one job.
sdata=$data/split$nj
utils/split_data_cmvn_utt.sh $data $nj

mkdir -p $dir/log
echo $nj > $dir/num_jobs

[ -z "$transform_dir" ] && transform_dir=$dir
if [ -z "$cmvn_opts" ]; then
  cmvn_opts=`cat $dir/cmvn_opts 2>/dev/null`
fi
echo $cmvn_opts >$dir/cmvn_opts 2>/dev/null

## Set up features.  Note: these are different from the normal features
## because we have one rspecifier that has the features for the entire
## training set, not separate ones for each batch.
if [ -z $feat_type ]; then
  if [ -f $dir/*.mat ] && ! [ -f $dir/raw_trans.1 ]; then feat_type=lda; else feat_type=raw; fi
fi
echo "$0: feature type is $feat_type"


# If we have more than $num_feats feature files (default: 10k),
# we use a random subset.  This won't affect the transform much, and will
# spare us an unnecessary pass over the data.  Probably 10k is
# way too much, but for small datasets this phase is quite fast.
N=$[$num_feats/$nj]

case $feat_type in 
 
	# no cmvn
       #	raw) feats="ark:copy-feats \"scp:utils/subset_scp.pl --quiet $N $sdata/JOB/feats.scp |\" ark:- |"

# normalize by spk
 #raw) feats="ark,s,cs:utils/subset_scp.pl --quiet $N $sdata/JOB/feats.scp | apply-cmvn $cmvn_opts --utt2spk=ark:$sdata/JOB/utt2spk scp:$sdata/JOB/cmvn.scp scp:- ark:- |"

# normalize by utt, not by spk
 raw) feats="ark,s,cs:utils/subset_scp.pl --quiet $N $sdata/JOB/feats.scp | apply-cmvn $cmvn_opts  scp:$sdata/JOB/cmvn.scp scp:- ark:- |"
    echo $cmvn_opts >$dir/cmvn_opts
   ;;
  lda) 
    splice_opts=`cat $dir/splice_opts 2>/dev/null`
    cp $dir/{splice_opts,cmvn_opts,final.mat} $dir || exit 1;
    [ ! -z "$cmvn_opts" ] && \
       echo "You cannot supply --cmvn-opts option of feature type is LDA." && exit 1;
    cmvn_opts=$(cat $dir/cmvn_opts)
     feats="ark,s,cs:utils/subset_scp.pl --quiet $N $sdata/JOB/feats.scp | apply-cmvn $cmvn_opts --utt2spk=ark:$sdata/JOB/utt2spk scp:$sdata/JOB/cmvn.scp scp:- ark:- | splice-feats $splice_opts ark:- ark:- | transform-feats $dir/final.mat ark:- ark:- |"
    ;;
  *) echo "$0: invalid feature type $feat_type" && exit 1;
esac

if [ -f $transform_dir/trans.1 ] && [ $feat_type != "raw" ]; then
  echo "$0: using transforms from $transform_dir"
  feats="$feats transform-feats --utt2spk=ark:$sdata/JOB/utt2spk ark:$transform_dir/trans.JOB ark:- ark:- |"
fi
if [ -f $transform_dir/raw_trans.1 ] && [ $feat_type == "raw" ]; then
  echo "$0: using raw-fMLLR transforms from $transform_dir"
  feats="$feats traGnsform-feats --utt2spk=ark:$sdata/JOB/utt2spk ark:$transform_dir/raw_trans.JOB ark:- ark:- |"
fi


feats_one="$(echo "$feats" | sed s:JOB:1:g)"
# note: feat_dim is the raw, un-spliced feature dim without the iVectors.
feat_dim=$(feat-to-dim "$feats_one" -) || exit 1;
# by default: no dim reduction.

spliced_feats="$feats splice-feats --left-context=$left_context --right-context=$right_context ark:- ark:- |"


if [ -z "$lda_dim" ]; then
  spliced_feats_one="$(echo "$spliced_feats" | sed s:JOB:1:g)"  
  lda_dim=$(feat-to-dim "$spliced_feats_one" -) || exit 1;
fi

if [ $stage -le 0 ]; then
  echo "$0: Accumulating LDA statistics."
  rm $dir/lda.*.acc 2>/dev/null # in case any left over from before.
  $cmd JOB=1:$nj $dir/log/lda_acc.JOB.log \
     copy-post ark:$post ark:- \|  \
      acc-lda-no-model --rand-prune=$rand_prune $lda_dim $num_state "$spliced_feats" ark:- \
       $dir/lda.JOB.acc || exit 1;
fi

echo $feat_dim > $dir/feat_dim
echo $lda_dim > $dir/lda_dim

if [ $stage -le 1 ]; then
  sum-lda-accs --binary=false $dir/final.acc $dir/lda.*.acc 2>$dir/log/lda_sum.log || exit 1;
  rm $dir/lda.*.acc
fi

if [ $stage -le 2 ]; then
	est-lda --dim=$ldadim --binary=false $dir/final.mat $dir/final.acc \
		2>$dir/log/lda_est.log || exit 1;
fi

echo "$0: Finished estimating LDA"

if [ $stage -le 3 ]; then
    # $cmd JOB=1:$nj $ldadir/log/transform_feats.JOB.log \
     # utils/subset_scp.pl --quiet $N $sdata/JOB/feats.scp | apply-cmvn --utt2spk=ark:$sdata/JOB/utt2spk scp:$sdata/JOB/cmvn.scp scp:- ark:- | splice-feats $splice_opts ark:- ark:- | transform-feats $dir/final.mat ark:- ark,scp:$ldadir/${data}_feat_lda.ark,$ldadir/${data}_feat_lda.scp || exit 1;
     #apply-cmvn --utt2spk=ark:$data/utt2spk scp:$data/cmvn.scp scp:$data/feats.scp ark:- | splice-feats --left-context=5 --right-context=5 ark:- ark:- | transform-feats $dir/final.mat ark:- ark,scp:$ldadir/test_feat_lda.ark,$ldadir/test_feat_lda.scp
    if [ ! -d $ldadir/$datatype ]; then
	    echo "ldadir is $ldadir"
	    mkdir -p $ldadir/$datatype
    fi
    splice-feats --left_context=5 --right_context=5 scp:$data/feats.scp ark:- | transform-feats $dir/final.mat ark:- ark,scp:$ldadir/$datatype/feasts.ark,$ldadir/$datatype/feats.scp
    steps/compute_cmvn_stats_per_utt.sh $ldadir/$datatype $cmvndir/lda_dim_${dim}_${posttype}_${datatype} $cmvndir/lda_dim_${dim}_${posttype}_${datatype}
    apply-cmvn scp:$ldadir/$datatype/cmvn.scp scp:$ldadir/$datatype/feats.scp ark,scp:$ldadir/$datatype/feats_cmvn.ark,$ldadir/$datatype/feats_cmvn.scp

    # apply-cmvn scp:$data/cmvn.scp scp:$data/feats.scp ark:- | splice-feats --left-context=5 --right-context=5 ark:- ark:- | transform-feats $dir/final.mat ark:- ark,scp:$ldadir/test_feat_lda.ark,$ldadir/test_feat_lda.scp

fi

