package Dancer::Plugin::Catmandu;
use strict;
use warnings;
use Dancer::Plugin;
use Catmandu;

our $VERSION = '0.1';

register new_store => \&Catmandu::new_store;
register new_index => \&Catmandu::new_index;
register new_filestore => \&Catmandu::new_filestore;
register new_importer => \&Catmandu::new_importer;
register new_exporter => \&Catmandu::new_exporter;
register get_store => \&Catmandu::get_store;
register get_index => \&Catmandu::get_index;
register get_filestore => \&Catmandu::get_filestore;

register_plugin;

1;
