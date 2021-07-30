#!/bin/bash

. ./cmd.sh ## You'll want to change cmd.sh to something that will work on your system.
           ## This relates to the queue.
. ./path.sh

stage=4
. utils/parse_options.sh

lstm_layer_num=4     # number of LSTM layers
lstm_cell_dim=640    # number of memory cells in every LSTM layer
dir=exp/train_phn_l${lstm_layer_num}_c${lstm_cell_dim}_pytorch  
if [ $stage -le 4 ]; then

  echo =====================================================================
  echo "                Pytorch Network Training                           "
  echo =====================================================================
  # Specify network structure and generate the network topology
  #input_feat_dim=120   # dimension of the input features; we will use 40-dimensional fbanks with deltas and double deltas
  lstm_layer_num=4     # number of LSTM layers
  lstm_cell_dim=640    # number of memory cells in every LSTM layer
  #target_num=`cat data/local/dict_phn/units.txt | wc -l`; target_num=$[$target_num+1]; # the number of targets                    
  epoch_num=10
  
  dir=exp/train_phn_l${lstm_layer_num}_c${lstm_cell_dim}_pytorch                                  
  mkdir -p $dir/model

  # Train the network with CTC. Refer to the script for details about the arguments
  python3 pytorch/train.py \
    --model_conf conf/model.json \
    --train_data_dir data/train \
    --cv_data_dir data/dev \
    --model_dir $dir/model \
    --epoch 20
fi


