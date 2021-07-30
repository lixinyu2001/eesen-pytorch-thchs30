#!/bin/bash
. ./cmd.sh ## You'll want to change cmd.sh to something that will work on your system.
           ## This relates to the queue.
. path.sh

. parse_options.sh


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
  
