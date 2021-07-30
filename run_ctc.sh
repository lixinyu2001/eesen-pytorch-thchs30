#!/bin/bash


./make_TLG_WFST.sh

./features.sh

./prep_train.sh

./train.sh

./decode.sh



