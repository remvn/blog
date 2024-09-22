#!/bin/bash 

export HUGO_MODULE_REPLACEMENTS="github.com/remvn/blog -> .., github.com/remvn/hugo-vmoji -> /home/remvn/personal/hugo-vmoji"
echo $HUGO_MODULE_REPLACEMENTS
hugo serve
