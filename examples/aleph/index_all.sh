#!/bin/bash

ls incoming/rug01.* | parallel -j4 "${HOME}/aleph/bin/aleph2solr"
