#!/usr/bin/env bash

# 
# Acoustic Unit Discovery based on infinite phone-loop model.
#

if [ $# -ne 1 ] 
    then
    echo "usage: $0 <setup.sh>"
    exit 1
fi

setup=$1

source $setup || exit 1


# Copy setup.sh to the experiment directory so that it can be re-run.
if [ -e $root/$model_type/setup.sh ]; then
  diff $setup $root/$model_type/setup.sh >/dev/null \
    || echo "Warning: $model_type/setup.sh differs; not overwriting" >&2
else
  mkdir -p $root/$model_type
  cp $setup $root/$model_type/setup.sh
fi

n=0 

echo "($((++n))) Data preparation..."
#local/prepare_data.sh $setup || exit 1
#local/prepare_data_clsp.sh $setup || exit 1 # Use this on clsp grid
echo done

echo "($((++n))) Features extraction..."
#utils/extract_features_BNF.sh $setup || exit 1
echo done

echo "($((++n))) Creating the model..."
echo "fea_dir is $fea_dir"
utils/phone_loop_create.sh \
	$setup \
	$train_keys \
        $root/$model_type/initial_model || exit 1
echo done

echo "($((++n))) Creating switched features model..."
utils/phone_loop_switch_features.sh \
        $setup \
        "-q $queues -l arch=\"*64\"" \
	$train_keys \
	$mfcc_model \
	$fea_dir \
	$root/$model_type/initial_model \
	$root/$model_type/unigram_switched || exit 1
echo done
#
echo "($((++n))) Training the model with unigram LM..."
utils/phone_loop_train.sh \
	$setup \
        "-q $queues -l arch=\"*64\"" \
	20 \
        $train_keys \
       	$root/$model_type/unigram_switched \
        $root/$model_type/unigram || exit 1
echo done

echo "($((++n))) Labeling the unigram model..."
utils/phone_loop_label.sh \
	$setup \
	"-q $queues -l arch=\"*64\"" \
	$train_keys \
	$root/$model_type/unigram \
	$root/$model_type/unigram_labels || exit 1
echo done

echo "($((++n))) Scoring the unigram model..."
utils/score_labels.sh \
	$setup \
	$test_keys \
	$root/$model_type/unigram_labels \
        $root/$model_type/score_unigram || exit 1
echo done

exit 0
echo "($((++n))) Retraining the phone loop with a bigram LM..."
echo "path: $root/$model_type/bigram"
utils/phone_loop_retrain.sh $setup 5 5 $root/$model_type/unigram \
    $root/$model_type/bigram || exit 1
echo done

echo "($((++n))) Labeling the bigram model..."
utils/phone_loop_label.sh $setup  $root/$model_type/bigram \
    $root/$model_type/bigram_labels || exit 1
echo done

echo "($((++n))) Scoring the bigram model..."
utils/score_labels.sh $setup $root/$model_type/bigram_labels \
    $root/$model_type/score_bigram || exit 1
echo done

