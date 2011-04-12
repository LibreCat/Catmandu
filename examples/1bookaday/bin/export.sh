#!/bin/bash

DATA_FILE=../data/tweets.db

catmandu export -s path=$DATA_FILE --pretty
