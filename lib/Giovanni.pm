package Giovanni;

use 5.8.0;
use Any::Moose;
use Net::OpenSSH;
use Sys::Hostname;
use Cwd;

=head1 NAME

Giovanni - The great new Giovanni!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

has 'debug' => (
    is        => 'rw',
    isa       => 'Bool',
    required  => 1,
    default   => 0,
    predicate => 'is_debug',
);

has 'hostname' => (
    is      => 'rw',
    isa     => 'Str',
    default => hostname()
);

has 'repo' => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
    default  => cwd(),
);

has 'scm' => (
    is      => 'rw',
    isa     => 'Str',
    default => 'git',
);

has 'role' => (
    is      => 'rw',
    isa     => 'Str',
    default => 'web',
);

has 'deploy_to' => (
    is      => 'rw',
    isa     => 'Str',
    default => '/var/www',
);

has 'user' => (
    is      => 'rw',
    isa     => 'Str',
    default => 'deploy',
);

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Giovanni;

    my $foo = Giovanni->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 deploy

=cut

sub deploy {
    my ( $self, $conf ) = @_;

    # load SCM plugin
    $self->load_plugin( $self->scm );
    my $tag = $self->tag();

}

=head2 rollback

=cut

sub rollback {
    my ( $self, $conf, $offset ) = @_;

    # load SCM plugin
    $self->load_plugin( $self->scm );
    my $tag = $self->get_last_tag($offset);
    print STDERR "Rolling back to tag: $tag\n" if $self->is_debug;
}

=head2 restart

=cut

sub restart {
}

sub load_plugin {
    my ( $self, $plugin ) = @_;

    my $plug = 'Giovanni::Plugins::' . ucfirst( lc($plugin) );
    print STDERR "Loading $plugin Plugin\n" if $self->is_debug;
    with($plug);
    return;
}

=head1 AUTHOR

Lenz Gschwendtner, C<< <norbu09 at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-giovanni at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Giovanni>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Giovanni


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Giovanni>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Giovanni>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Giovanni>

=item * Search CPAN

L<http://search.cpan.org/dist/Giovanni/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Lenz Gschwendtner.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;
