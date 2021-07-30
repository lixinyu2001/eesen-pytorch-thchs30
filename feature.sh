#!/bin/bash
. ./cmd.sh ## You'll want to change cmd.sh to something that will work on your system.
           ## This relates to the queue.
. path.sh

. parse_options.sh

echo =====================================================================
echo "                    FBank Feature Generation                       "
echo =====================================================================
fbankdir=fbank

# Generate the fbank features; by default 40-dimensional fbanks on each frame
#make train fbank
steps/make_fbank.sh --cmd "$train_cmd" --nj 10 data/train exp/make_fbank/train $fbankdir || exit 1;
utils/fix_data_dir.sh data/train || exit;
steps/compute_cmvn_stats.sh data/train exp/make_fbank/train $fbankdir || exit 1;
echo -e "\n"

#make test fbank
steps/make_fbank.sh --cmd "$train_cmd" --nj 6 data/test exp/make_fbank/test $fbankdir || exit 1;
utils/fix_data_dir.sh data/test || exit;
steps/compute_cmvn_stats.sh data/test exp/make_fbank/test $fbankdir || exit 1;
echo -e "\n"

#make dev fbank
steps/make_fbank.sh --cmd "$train_cmd" --nj 6 data/dev exp/make_fbank/dev $fbankdir || exit 1;
utils/fix_data_dir.sh data/dev || exit;
steps/compute_cmvn_stats.sh data/dev exp/make_fbank/dev $fbankdir || exit 1;
echo -e "\n"


echo =====================================================================
echo "                Prepare Network Training data                      "
echo =====================================================================
# Label sequences; simply convert words into their label indices
# 根据词典lexicon_numbers.txt 给 data/***/text生成对应的label.scp,生成训练的标签，有不认识的词用 <UNK>标记，<UNK>对应的值为1
# 对feats.scp中的数据进行语音长度大小排序，避免批次训练时，同一批数据的长度大小悬殊
for set in train dev; do
   python3 utils/prep_ctc_trans.py data/dict_phn/lexicon_numbers.txt data/$set/text "<UNK>" |tee data/$set/labels.scp |gzip -c - > data/$set/labels.gz
   utils/sort_feature_by_len.sh data/$set/feats.scp data/$set/feats.sort.scp 6
done
  
