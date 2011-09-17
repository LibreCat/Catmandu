package Dancer::Plugin::Catmandu;
use strict;
use warnings;
use Dancer::Plugin;
use Catmandu;

our $VERSION = '0.1';

register new_store => \&Catmandu::new_store;
register new_index => \&Catmandu::new_index;
register new_filestore => \&Catmandu::new_filestore;
register get_store => \&Catmandu::get_store;
register get_index => \&Catmandu::get_index;
register get_filestore => \&Catmandu::get_filestore;

register_plugin;

1;
