package Manaba_test;
use Dancer ':syntax';

our $VERSION = '0.1';

use 5.010;
use YAML::Tiny;
use Data::Dumper;

my $CONFIG;

get '/' => sub {
    template 'index';
};

sub load_manaba {
    my $yaml = YAML::Tiny->read( config->{manaba} );
    $CONFIG = $yaml->[0];
}

load_manaba();
debug Dumper \$CONFIG;

true;
