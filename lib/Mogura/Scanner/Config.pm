package Mogura::Scanner::Config;
use Mojo::Base -base;

has state => '/var/lib/mogura-scanner';
has runtime => '/run/mogura-scanner';
has syft => '/usr/local/bin/syft';
has grype => '/usr/local/bin/grype';
has command_timeout => 3600;
has jobs => 2;
has inventory_interval => 10;

has spool_limit => 8 * 1024**3;

sub mounts {
    my ($self) = @_;
    return $self->runtime . '/mounts';
}

1;
