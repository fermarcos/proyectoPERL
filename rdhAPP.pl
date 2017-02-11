#!/usr/bin/perl -w

use strict;
use lib '.'; # se indica donde va a buscar los modulos
use registrosRDH;

my $app = registrosRDH->new();
$app->run();
