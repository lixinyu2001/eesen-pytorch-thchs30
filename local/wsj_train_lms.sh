#!/bin/bash

# This script comes from Kaldi. It retrains the language models using the expanded
# lexicon/vocabulary.
# It demonstrates how to build LMs using the kaldi_lm, SRILM, IRSTLM toolkits. Although
# we use the LMs built by kaldi_lm in the subsequent steps, LMs built by the other two
# toolkits can be used as well.

dir=data/local/local_lm
srcdir=data/local/dict_char_larger   # the expanded lexicon

mkdir -p $dir
. ./path.sh || exit 1; # for EESEN_ROOT
export PATH=$EESEN_ROOT/tools/kaldi_lm:$PATH
( # First make sure the kaldi_lm toolkit is installed.
 cd $EESEN_ROOT/tools || exit 1;
 if [ -d kaldi_lm ]; then
   echo Not installing the kaldi_lm toolkit since it is already there.
 else
   echo Downloading and installing the kaldi_lm tools
   if [ ! -f kaldi_lm.tar.gz ]; then
     wget http://www.danielpovey.com/files/kaldi/kaldi_lm.tar.gz || exit 1;
   fi
   tar -xvzf kaldi_lm.tar.gz || exit 1;
   cd kaldi_lm
   make || exit 1;
   echo Done making the kaldi_lm tools
 fi
) || exit 1;



if [ ! -f $srcdir/cleaned.gz -o ! -f $srcdir/lexicon.txt ]; then
  echo "Expecting files $srcdir/cleaned.gz and $srcdir/lexicon.txt to exist";
  echo "You need to run local/wsj_extend_dict.sh before running this script."
  exit 1;
fi

# Get a wordlist-- keep everything but silence, which should not appear in
# the LM.
awk '{print $1}' $srcdir/lexicon.txt | grep -v -w '!SIL' > $dir/wordlist.txt

# Get training data with OOV words (w.r.t. our current vocab) replaced with <UNK>.
echo "Getting training data with OOV words replaced with <UNK> (train_nounk.gz)" 
gunzip -c $srcdir/cleaned.gz | awk -v w=$dir/wordlist.txt \
  'BEGIN{while((getline<w)>0) v[$1]=1;}
  {for (i=1;i<=NF;i++) if ($i in v) printf $i" ";else printf "<UNK> ";print ""}'|sed 's/ $//g' \
  | gzip -c > $dir/train_nounk.gz

# Get unigram counts (without bos/eos, but this doens't matter here, it's
# only to get the word-map, which treats them specially & doesn't need their
# counts).
# Add a 1-count for each word in word-list by including that in the data,
# so all words appear.
gunzip -c $dir/train_nounk.gz | cat - $dir/wordlist.txt | \
  awk '{ for(x=1;x<=NF;x++) count[$x]++; } END{for(w in count){print count[w], w;}}' | \
 sort -nr > $dir/unigram.counts

# Get "mapped" words-- a character encoding of the words that makes the common words very short.
cat $dir/unigram.counts  | awk '{print $2}' | get_word_map.pl "<s>" "</s>" "<UNK>" > $dir/word_map

gunzip -c $dir/train_nounk.gz | awk -v wmap=$dir/word_map 'BEGIN{while((getline<wmap)>0)map[$1]=$2;}
  { for(n=1;n<=NF;n++) { printf map[$n]; if(n<NF){ printf " "; } else { print ""; }}}' | gzip -c >$dir/train.gz

# To save disk space, remove the un-mapped training data.  We could
# easily generate it again if needed.
rm $dir/train_nounk.gz 

train_lm.sh --arpa --lmtype 3gram-mincount $dir
#Perplexity over 228518.000000 words (excluding 478.000000 OOVs) is 141.444826
# 7.8 million N-grams.

prune_lm.sh --arpa 6.0 $dir/3gram-mincount/
# 1.45 million N-grams.
# Perplexity over 228518.000000 words (excluding 478.000000 OOVs) is 165.394139

train_lm.sh --arpa --lmtype 4gram-mincount $dir
#Perplexity over 228518.000000 words (excluding 478.000000 OOVs) is 126.734180
# 10.3 million N-grams.

prune_lm.sh --arpa 7.0 $dir/4gram-mincount
# 1.50 million N-grams
# Perplexity over 228518.000000 words (excluding 478.000000 OOVs) is 155.663757


exit 0

### Below here, this script is showing various commands that 
## were run during LM tuning.

train_lm.sh --arpa --lmtype 3gram-mincount $dir
#Perplexity over 228518.000000 words (excluding 478.000000 OOVs) is 141.444826
# 7.8 million N-grams.

prune_lm.sh --arpa 3.0 $dir/3gram-mincount/
#Perplexity over 228518.000000 words (excluding 478.000000 OOVs) is 156.408740
# 2.5 million N-grams.

prune_lm.sh --arpa 6.0 $dir/3gram-mincount/
# 1.45 million N-grams.
# Perplexity over 228518.000000 words (excluding 478.000000 OOVs) is 165.394139

train_lm.sh --arpa --lmtype 4gram-mincount $dir
#Perplexity over 228518.000000 words (excluding 478.000000 OOVs) is 126.734180
# 10.3 million N-grams.

prune_lm.sh --arpa 3.0 $dir/4gram-mincount
#Perplexity over 228518.000000 words (excluding 478.000000 OOVs) is 143.206294
# 2.6 million N-grams.

prune_lm.sh --arpa 4.0 $dir/4gram-mincount
# Perplexity over 228518.000000 words (excluding 478.000000 OOVs) is 146.927717
# 2.15 million N-grams.

prune_lm.sh --arpa 5.0 $dir/4gram-mincount
# 1.86 million N-grams
# Perplexity over 228518.000000 words (excluding 478.000000 OOVs) is 150.162023

prune_lm.sh --arpa 7.0 $dir/4gram-mincount
# 1.50 million N-grams
# Perplexity over 228518.000000 words (excluding 478.000000 OOVs) is 155.663757

train_lm.sh --arpa --lmtype 3gram $dir
# Perplexity over 228518.000000 words (excluding 478.000000 OOVs) is 135.692866
# 20.0 million N-grams

! which ngram-count  \
  && echo "SRILM tools not installed so not doing the comparison" && exit 1;

#################
# You could finish the script here if you wanted.
# Below is to show how to do baselines with SRILM.
#  You'd have to install the SRILM toolkit first.

heldout_sent=10000 # Don't change this if you want result to be comparable with
    # kaldi_lm results
sdir=$dir/srilm # in case we want to use SRILM to double-check perplexities.
mkdir -p $sdir
gunzip -c $srcdir/cleaned.gz | head -$heldout_sent > $sdir/cleaned.heldout
gunzip -c $srcdir/cleaned.gz | tail -n +$heldout_sent > $sdir/cleaned.train
(echo "<s>"; echo "</s>" ) | cat - $dir/wordlist.txt > $sdir/wordlist.final.s

# 3-gram:
ngram-count -text $sdir/cleaned.train -order 3 -limit-vocab -vocab $sdir/wordlist.final.s -unk \
  -map-unk "<UNK>" -kndiscount -interpolate -lm $sdir/srilm.o3g.kn.gz
ngram -lm $sdir/srilm.o3g.kn.gz -ppl $sdir/cleaned.heldout # consider -debug 2
#file data/local/local_lm/srilm/cleaned.heldout: 10000 sentences, 218996 words, 478 OOVs
#0 zeroprobs, logprob= -491456 ppl= 141.457 ppl1= 177.437

# Trying 4-gram:
ngram-count -text $sdir/cleaned.train -order 4 -limit-vocab -vocab $sdir/wordlist.final.s -unk \
  -map-unk "<UNK>" -kndiscount -interpolate -lm $sdir/srilm.o4g.kn.gz
ngram -order 4 -lm $sdir/srilm.o4g.kn.gz -ppl $sdir/cleaned.heldout 
#file data/local/local_lm/srilm/cleaned.heldout: 10000 sentences, 218996 words, 478 OOVs
#0 zeroprobs, logprob= -480939 ppl= 127.233 ppl1= 158.822

#3-gram with pruning:
ngram-count -text $sdir/cleaned.train -order 3 -limit-vocab -vocab $sdir/wordlist.final.s -unk \
  -prune 0.0000001 -map-unk "<UNK>" -kndiscount -interpolate -lm $sdir/srilm.o3g.pr7.kn.gz
ngram -lm $sdir/srilm.o3g.pr7.kn.gz -ppl $sdir/cleaned.heldout 
#file data/local/local_lm/srilm/cleaned.heldout: 10000 sentences, 218996 words, 478 OOVs
#0 zeroprobs, logprob= -510828 ppl= 171.947 ppl1= 217.616
# Around 2.25M N-grams.
# Note: this is closest to the experiment done with "prune_lm.sh --arpa 3.0 $dir/3gram-mincount/"
# above, which gave 2.5 million N-grams and a perplexity of 156.

# Note: all SRILM experiments above fully discount all singleton 3 and 4-grams.
# You can use -gt3min=0 and -gt4min=0 to stop this (this will be comparable to
# the kaldi_lm experiments above without "-mincount".

##  From here is how to train with
# IRSTLM.  This is not really working at the moment.
export IRSTLM=$EESEN_ROOT/tools/irstlm/

idir=$dir/irstlm
mkdir $idir
gunzip -c $srcdir/cleaned.gz | tail -n +$heldout_sent | $IRSTLM/scripts/add-start-end.sh | \
  gzip -c > $idir/train.gz

$IRSTLM/bin/dict -i=WSJ.cleaned.irstlm.txt -o=dico -f=y -sort=no
 cat dico | gawk 'BEGIN{while (getline<"vocab.20k.nooov") v[$1]=1; print "DICTIONARY 0 "length(v);}FNR>1{if ($1 in v)\
{print $0;}}' > vocab.irstlm.20k


$IRSTLM/bin/build-lm.sh -i "gunzip -c $idir/train.gz" -o $idir/lm_3gram.gz  -p yes \
  -n 3 -s improved-kneser-ney -b yes
# Testing perplexity with SRILM tools:
ngram -lm $idir/lm_3gram.gz  -ppl $sdir/cleaned.heldout 
#data/local/local_lm/irstlm/lm_3gram.gz: line 162049: warning: non-zero probability for <unk> in closed-vocabulary LM
#file data/local/local_lm/srilm/cleaned.heldout: 10000 sentences, 218996 words, 0 OOVs
#0 zeroprobs, logprob= -513670 ppl= 175.041 ppl1= 221.599

# Perplexity is very bad (should be ~141, since we used -p option,
# not 175),
# but adding -debug 3 to the command line shows that
# the IRSTLM LM does not seem to sum to one properly, so it seems that
# it produces an LM that isn't interpretable in the normal way as an ARPA
# LM.

