#!/bin/bash

. ./cmd.sh ## You'll want to change cmd.sh to something that will work on your system.
           ## This relates to the queue.
. ./path.sh

stage=5
. utils/parse_options.sh

lstm_layer_num=4     # number of LSTM layers
lstm_cell_dim=640    # number of memory cells in every LSTM layer
dir=exp/train_phn_l${lstm_layer_num}_c${lstm_cell_dim}_pytorch  

if [ $stage -le 5 ]; then
  # Send training/cv data ctc model and count greedy decoding result
  # Here we use a pre-count stats
  echo =====================================================================
  echo "                            Decoding                               "
  echo =====================================================================
  # Config for the basic decoding: --beam 30.0 --max-active 5000 --acoustic-scales "0.7 0.8 0.9"
  split_data.sh  data/test 2  || exit 1;
  for lm_suffix in tgpr; do
    steps/decode_ctc_lat_pytorch.sh --cmd "$decode_cmd" --nj 2 --beam 17.0 --lattice_beam 8.0 --max-active 5000 --acwt 0.9 \
      data/search_Graph $dir/model/final.pt data/test  $dir/test_${lm_suffix} || exit 1;

  done
fi
