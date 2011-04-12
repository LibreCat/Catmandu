#!/bin/bash

DATA_FILE=../data/tweets.db

catmandu import -I Atom -i url=http://search.twitter.com/search.atom?q=obana -s path=$DATA_FILE
