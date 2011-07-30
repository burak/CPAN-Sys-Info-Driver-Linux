#!/usr/bin/env perl -w
use strict;
use warnings;
use Test::Sys::Info;

diag(qx(uname -a));

driver_ok('Linux');
