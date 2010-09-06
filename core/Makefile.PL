# This Makefile.PL is required to execure all test scripts in the t/* directory
use strict;
use inc::Module::Install;

name         'Catmandu-Core';
license      'perl';
perl_version '5.10.0';
version      '0.1';
no_index     'core';

WriteAll;
