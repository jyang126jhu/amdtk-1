#
# This file defines all the configuration variables for a particular
# experiment. Set the different paths according to your system. Most of the
# values predefined here are generic and should yield decent results.
# However, they are most likely not optimal and need to be tuned for each
# particular data set.
#

############################################################################
# Directories.                                                             #
############################################################################
db_path=/export/corpora/LDC/LDC93S1/timit/TIMIT
#db_path=/mnt/matylda2/data/TIMIT/timit
root=$(pwd -P)

############################################################################
# SGE settings.                                                            #
############################################################################

# Set your parallel environment. Supported environment are:
#   * local
#   * sge
#   * openccs.
export AMDTK_PARALLEL_ENV="sge"

parallel_n_core=100
parallel_profile="--profile $root/path.sh"

## SGE - BUT ##
#queues="all.q@@stable"

## SGE - CLSP ##
 queues="all.q"

parallel_opts="-q $queues -l arch=*64"

############################################################################
# Splitting of the data base (train/dev/test set).                         #
############################################################################
train_keys="$root/data/train.keys"
test_keys="$root/data/test.keys"
all_keys="$root/data/all.keys"

############################################################################
# Features settings.                                                       #
############################################################################
scp="$root/data/all.scp"
fea_ext='fea'
#fea_type=BNF_dim_40_lr_0.008_1best_mfcc_ac1_c1_T100_s3_g2_300tgt_theano
fea_type=LDA_dim_40_1best_mfcc_ac1_s3_g2_sil_10_states
fea_dir="$root/$fea_type"
mfcc_fea_dir=/export/b07/jyang/AMDTK/recipes/timit/mfcc/
#fea_dir=$mfcc_fea_dir
fea_conf="$root/conf/$fea_type.cfg"
mfcc_model=ploop_mfcc_c1_T100_sil10_s3_g2_a3_b3/unigram

############################################################################
# Model settings.                                                          #
############################################################################
#sil_ngauss=10
sil_ngauss=10
concentration=1
truncation=100
nstates=3
ncomponents=2
alpha=3
kappa=5
a=3
b=3
model_type="ploop_${fea_type}_c${concentration}_T${truncation}_sil${sil_ngauss}_s${nstates}_g${ncomponents}_a${a}_b${b}"

unigram_ac_weight=1.0

############################################################################
# Language model training.                                                 #
############################################################################
lm_params=".5,1:.5,1"

############################################################################
# Posteriors generation.                                                   #
############################################################################
post_ac_weight=1

############################################################################
# Lattices and counts generation.                                          #
############################################################################
beam_thresh=0.0
penalty=-1
gscale=1
conf_latt_dir="${root}/${model_type}/conf_lattices"



###########post###############
fb_post_dir=post/htk/fb/fb_mfcc_s2_g2
kaldi_post_dir=post/kaldi/fb/fb_mfcc_s3_g2
post_parallel_opts=$parallel_opts
fb_post_keys=$train_keys
post_keys=$fb_post_keys
post_ext="pos"
label_dir_train=$model_type/unigram_labels

