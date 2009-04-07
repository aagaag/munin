package Munin::Common::TLSClient;
use base qw(Munin::Common::TLS);

use warnings;
use strict;

use Carp;
use English qw(-no_match_vars);

sub new {
    my ($class, $args) = @_;
    
    my $self = $class->SUPER::new($args);

    $self->{remote_key} = 0;
    return $self;
}


sub start_tls {
    my ($self) = @_;

    $self->SUPER::_start_tls();
}


sub _initial_communication {
    my ($self) = @_;
    
    $self->{write_func}("STARTTLS\n");
    my $tlsresponse = $self->{read_func}();
    if (!defined $tlsresponse) {
        $self->{logger}("[ERROR] Bad TLS response \"\".");
        return 0
    }
    if ($tlsresponse =~ /^TLS OK/) {
        $self->{remote_key} = 1;
    }
    elsif ($tlsresponse !~ /^TLS MAYBE/i) {
        $self->{logger}("[ERROR] Bad TLS response \"$tlsresponse\".");
        return 0;
    }

    return 1;
}


sub _use_key_if_present {
    my ($self) = @_;

    return !$self->{remote_key};
}


sub _on_unverified_cert {
    my ($self) = @_;

    $self->write("quit\n");
}


1;

=head1 NAME

Munin::Node::TLS - Implements the server side of the STARTTLS protocol


=head1 SYNOPSIS

FIX


=head1 METHODS

=over

=item B<new>

FIX

=item B<start_tls>

FIX

=back
