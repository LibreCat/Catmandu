#!/bin/bash
#
# Travis like test/cover
#
# Usage:
#    travis_test.sh       (all tests)
#    travis_test.sh FILE  (one file)
#
# P@ 2017
FILE=$1

carton exec 'cpanm --notest Perl::Tidy'
carton exec 'cpanm --quiet --notest --skip-satisfied Devel::Cover'
carton exec 'perl Build.PL && ./Build build'

if [ -d cover_db ]; then
    rm -rf cover_db/
fi

if [ "${FILE}" != ""]; then
    carton exec "PERL5OPT=-MDevel::Cover env perl -Ilib ${FILE}"
else
    carton exec 'cover -test'
fi

if [ -d cover_db ]; then
    rm -rf cover_db/
fi
carton exec './Build realclean'
