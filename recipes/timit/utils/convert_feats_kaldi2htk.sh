#!/usr/bin/env bash

#
# Convert kaldi-feats to htk-feats
#

#if [ $# -ne 1 ]; then
#    echo "usage: $0 setup.sh"
#    exit 1
#fi

#kaldi_dir=/export/b07/jyang/AMDTK/recipes/timit_bn/s5/data-bnfeats/data-fbank/test_dim_40_lr_0.001_fb_c1_T100_s3_g2_a3_b3_lucas_unigram_fbank/feats_cmvn.scp

#kaldi_dir=/export/b07/jyang/AMDTK/recipes/timit_bn/s5/data-bnfeats/test_dim_40_lr_0.008_dpgmm_ac_1_c1_T100_num_tgt_100/feats_cmvn.scp
#kaldi_dir=/export/b07/jyang/AMDTK/recipes/timit_bn/s5/lda_dim_40_c1_T100_s3_g2_lucas_unigram_1best/test_feat_lda.scp
#kaldi_dir=/export/b07/jyang/AMDTK/recipes/timit_bn/s5/lda_dim_40_c1_T100_s3_g2_lucas_unigram_1best/test_feat_lda.scp

#kaldi_dir=/export/b07/jyang/AMDTK/recipes/timit_bn/s5/lda_dim_40_mfcc_dpgmm/test/feats_cmvn.scp
#setup="$1"
#source "$setup" || exit 1
# c10_c10
#fea_dir=LDA_dim_40_mfcc_dpgmm_1best_100tgt
#kaldi_dir=/export/b07/jyang/kaldi-harish/kaldi/egs/ami/s5/data-bnfeats/test

kaldi_dir=/export/b07/jyang/AMDTK-1/amdtk-1/recipes/timit_bn/s5/LDA/dim_40/1best_mfcc_s3_g2_sil_10_states/test/test
fea_dir=LDA_dim_40_1best_mfcc_ac1_s3_g2_sil_10_states
#fea_dir=BNF_bn_dim_40_lr0.008_1best_c1_T100_s3_g2_a3_b3_lucas_label
if [ ! -e "$fea_dir/.done" ]; then

	for file in $kaldi_dir/feats_cmvn.scp;do 
   # feats="ark,s,cs:copy-feats scp:$file ark:- | apply-cmvn scp:$kaldi_dir/cmvn.scp ark:- ark:- |"
    copy-feats-to-htk --output-dir=$fea_dir \
        --output-ext=fea \
         scp:$file || exit 1
   done
  
   echo "The features have been converted to $fea_dir."

    date > "$fea_dir"/.done
else
    echo The features have already been extracted. Skipping.
fi
