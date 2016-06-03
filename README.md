# String::Ngram
Text::MeCab based ngram module with perl

##Usage
###init
```
my $ngram = String::Ngram->new(TEXT::MECAB_INITIAL_ARGS);
```
###make marcov dictionary
```
$ngram->makedic(Str, Int);
```

###save dictionary data
```
$ngram->savefile(Str);
```

###load dictionary data
```
$ngram->loadfile(Str);
```

###generate sentense
```
$ngram->generate(Int);
```
  
##Example
```perl

#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use v5.10;
use Encode qw/encode_utf8 decode_utf8/;
use Data::Dumper;

use String::Ngram;

my $ngram = String::Ngram->new(dicdir => "/usr/local/lib/mecab/dic/mecab-ipadic-neologd");

my $input = encode_utf8 "今回のサミットで焦点となる世界経済を巡る討議は、午後３時半すぎに終わりました。この中で安倍総理大臣は「世界経済は今、まさに分岐点にあり、政策的対応を誤ると危機に陥るリスクがあることは認識しておかなければならない」という考えを示し、Ｇ７の結束を呼びかけたとみられます。。";

$ngram->makedic($input, 3);

# say Dumper $ngram->dictionary;

say $ngram->generate(16);
```

##License
MIT License.
