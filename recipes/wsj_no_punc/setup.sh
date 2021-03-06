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
## BUT ##
#wsj0=/mnt/matylda2/data/WSJ0
#wsj1=/mnt/matylda2/data/WSJ1

## CLSP ##
#wsj0=/export/corpora/LDC/LDC93S6A
wsj1=/export/corpora/LDC/LDC94S13A

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

############################################################################
# Features settings.                                                       #
############################################################################
scp=${root}/data/all.scp
fea_ext='fea'
fea_type=mfcc
fea_dir=$root/$fea_type
fea_conf=$root/conf/$fea_type.cfg

## SGE - BUT ##
#fea_parallel_opts="-q $queues -l scratch1=0.3"

## SGE - CLSP ##
fea_parallel_opts="-q $queues -l arch=*64"

############################################################################
# Model settings.                                                          #
############################################################################
concentration=1
truncation=100
eta=3
nstates=3
alpha=3
ncomponents=2
kappa=5
a=3
b=3
model_type=ploop_l${fea_type}_c${concentration}_T${truncation}_s${nstates}_g${ncomponents}_a${a}_b${b}

############################################################################
# Training settings.                                                       #
############################################################################
train_keys=$root/data/training_unique.keys

## SGE - BUT ## 
#train_parallel_opts="-q $queues -l scratch1=0.2,matylda5=0.3"

## SGE - CLSP ## 
train_parallel_opts="-q $queues -l arch=*64"

############################################################################
# Labeling settings.                                                       #
############################################################################
label_fea_dir=$fea_dir
label_dir=$root/$model_type/labels_$niter
label_keys=$root/data/all_unique.keys

## SGE - BUT ## 
#label_parallel_opts="-q $queues -l matylda5=0.3"

## SGE - CLSP ## 
label_parallel_opts="-q $queues -l arch=*64"

############################################################################
# Posteriors settings.                                                     #
############################################################################
post_keys=$root/data/all_unique.keys

## SGE - BUT ## 
#post_sge_res="-q $queues -l matylda5=0.3"

## SGE - BUT ## 
post_sge_res="-q $queues -l arch=*64"

############################################################################
# Lattices and counts generation.                                          #
############################################################################
beam_thresh=0.0
penalty=-1
gscale=1
latt_count_order=3
sfx=bt${beam_thresh}_p${penalty}_gs${gscale}
conf_latt_dir=${root}/${model_type}/conf_lattices
out_latt_dir=${root}/${model_type}/lattices_${sfx}_${niter}

## SGE - BUT ## 
#latt_parallel_opts="-q $queues -l matylda5=0.3"

## SGE - BUT ## 
latt_parallel_opts="-q $queues -l arch=*64"

