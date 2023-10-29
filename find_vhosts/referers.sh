#!/bin/bash

get_random_referer () {
local RANGE
local rnd

RANGE=35  #17+ --> for statistical normalization
rnd=$RANDOM
#echo "Current RANDOM: $rnd"
(( rnd %= RANGE ))
#echo "Random number less than $RANGE: $rnd"
case $rnd in
  0) echo "https://www.google.com/"
  ;;
  1) echo "https://www.facebook.com/"
  ;;
  2) echo "https://www.bing.com/"
  ;;
  3) echo "https://search.yahoo.com/"
  ;;
  4) echo "https://www.baidu.com/link?url=-TN5QnU0-G8uENDWPNC2NsO_0lwSWAPl4nJvpyV6D7KUAnjB-PazSweqcuptRjIVOs7CZ_U4rfeFzVlB_nfIrf7eAUhNyQy0Bn7PYelm-6y&wd=&eqid=95549483000df9870000007"
  ;;
  5) echo "https://www.qwant.com/"
  ;;
  6) echo "https://www.google.ru/"
  ;;
  7) echo "https://www.google.by/"
  ;;
  8) echo "https://www.google.com.ua"
  ;;
  9) echo "https://www.google.uz/"
  ;;
  10) echo "https://www.google.kz/"
  ;;
  11) echo "https://www.google.ge/"
  ;;
  12) echo "https://www.google.am/"
  ;;
  13) echo "https://nova.rambler.ru/search?utm_source=head&utm_campaign=self_promo&utm_medium=form&utm_content=search&query=$1"
  ;;
  14) echo "https://yandex.ru/"
  ;;
  15) echo "https://www.google.lv/"
  ;;
  16) echo "https://www.google.es/"
  ;;
  17) echo ""
  ;;
  *) echo ""
  ;;
esac
}

export -f get_random_referer
