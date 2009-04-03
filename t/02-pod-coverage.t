#!/usr/bin/env perl -w
use strict;
use Test::More;
eval q{use Test::Pod::Coverage; 1;};

$@ ? plan(skip_all => "Test::Pod::Coverage required for testing pod coverage")
   : all_pod_coverage_ok()
   ;
