thchs30_root=/data/thchs30

rm  -rf corpus
ln -s $thchs30_root/data_thchs30 corpus
mkdir -p data/dict
cp corpus/lm_word/lexicon.txt data/dict
mkdir -p data/language_model
cp corpus/lm_word/word.3gram.lm  data/language_model/lm
gzip  data/language_model/lm

