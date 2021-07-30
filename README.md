用pytorch+CTC+WFST实现中文汉语语音识别

最近专门空出来很多时间，准备把一直犹豫不决要不要写的智能理论写出来，同时准备用语音识别做一些实验，所以有了这个项目。
语音识别实验比可选的工具有kaldi，wav2letter，espnet等，使用比较广泛工具是kaldi，但是对于前端语音处理的部分，我觉得kaldi所使用的HMM-GMM方式相当的不直观，Kaldi所使用的nnet神经网络也不是目前主流的深度学习工具。而kaldi创建者Daniel Povey要推出的与pytorch接口良好的kaldi新的版本也还没有出来。但是kaldi的WFST解码系统在处理文本模型的表现相当的出色，我想要的工具是pytorch处理语音前端，再加上WFST处理文本模型。
我在网上找了一下，找到了一个项目比较满足我的需求，它就是github上的eesen（https://github.com/isi-vista/eesen），eesen和传统kaldi处理方式对比如下：
传统的kaldi处理方式：
    • Hidden Markov models (HMMs) 
    • Gaussian mixture models (GMMs) 
    • Decision trees and phonetic questions 
    • Dictionary, if characters are used as the modeling units 
    • ... 
eesen的处理方式：
    • Acoustic Model -- Bi-directional RNNs with LSTM units. 
    • Training -- Connectionist temporal classification (CTC) as the training objective. 
    • Decoding -- A principled decoding approach based on Weighted Finite-State Transducers (WFSTs). 

eesen项目最近的更新已经是两年前，所使用的依赖库也比较早期，对于神经网络的处理还是使用nnet，所使用的例子也是英文。所以在github上我又参考了两个相关的项目，一个是ctc-asr（https://github.com/placebokkk/ctc-asr）和 eesen-for-thchs30（https://github.com/Sundy1219/eesen-for-thchs30），经过一段时间的调试，我做了第一个实验，语音处理前端使用pytorch处理，其输出是基于拼音的概率矩阵，然后用WFST处理得到文字输出。
注意：首先要安装好eesen，由于这个项目时间久远，支持的库比较老，我折腾了好久，我目前在ubuntu16.04上编译成功，cuda使用的9.2版本，pytorch我使用anaconda安装，使用版本的是python3.7，pytorch1.2，cuda9.2。
使用的实验语料是清华实验室提供的thchs30，安装好后首先要在before_run.sh中设置好thchs30语料的所在的目录，然后运行run-ctc.sh，如果要继续训练，需要将exp/train*/model/final.pt 复制到exp/init.pt，然后运行train_continue.sh.

