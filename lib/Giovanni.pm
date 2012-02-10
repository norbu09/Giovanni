package Giovanni;

use 5.010;
use Mouse;
use Mouse::Util;
use Net::OpenSSH;
use Sys::Hostname;
use Cwd;
use Giovanni::Stages;

extends 'Giovanni::Stages';

=head1 NAME

Giovanni - The great new Giovanni!

=head1 VERSION

Version 0.8.8.7.7

=cut

our $VERSION = '0.8';

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
    default => hostname(),
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

has 'version' => (
    is      => 'rw',
    isa     => 'Str',
    default => 'v1',
);

has 'error' => (
    is  => 'rw',
    isa => 'Str',
);

has 'config' => (
    is       => 'rw',
    required => 1,
);

has 'notifyer' => (
    is      => 'rw',
    isa     => 'Str',
    default => 'jabber',
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
    my ($self) = @_;

    # load SCM plugin
    $self->load_plugin($self->scm);
    my $tag = $self->tag();
    my $ssh = $self->_get_ssh_conn;
    $self->process_stages($ssh, 'deploy');
}

=head2 rollback

=cut

sub rollback {
    my ($self, $offset) = @_;

    my $ssh = $self->_get_ssh_conn;
    $self->process_stages($ssh, 'rollback');
}

sub process_stages {
    my ($self, $ssh, $mode) = @_;

    my @stages = split(/\s*,\s*/, $self->config->{$mode});
    foreach my $stage (@stages) {
        $self->process_hosts($ssh, $stage, $mode);

        # if one host produced an error while restarting, rollback all
        if ($self->error and ($stage =~ m/^restart/i) and ($mode eq 'deploy')) {
            $self->log('ERROR', $self->error);
            $self->process_stages($ssh, 'rollback');
            return;
        }
    }
}

sub process_hosts {
    my ($self, $ssh, $stage, $mode) = @_;

    my @hosts = split(/\s*,\s*/, $self->config->{hosts});
    foreach my $host (@hosts) {
        $self->log($ssh->{$host}, "running $stage");
        $self->$stage($ssh->{$host});
    }
}

sub _get_ssh_conn {
    my ($self) = @_;

    my @hosts = split(/\s*,\s*/, $self->config->{hosts});
    my $ssh;
    foreach my $host (@hosts) {
        my $conn = $host;
        $conn = ($self->config->{user} || $self->user) . '@' . $host;
        $ssh->{$host} = Net::OpenSSH->new($conn, async => 1);
    }

    # trigger noop command to check for connection
    foreach my $host (@hosts) {
        $ssh->{$host}->test('echo')
            or confess "could not connect to $host: " . $ssh->{$host}->error;
        $self->log($host, 'connected');
    }
    return $ssh;
}

=head2 restart

=cut

sub restart {
}

sub load_plugin {
    my ($self, $plugin) = @_;

    my $plug = 'Giovanni::Plugins::' . ucfirst(lc($plugin));
    unless (Mouse::Util::is_class_loaded($plug)) {
        print STDERR "Loading $plugin Plugin\n" if $self->is_debug;
        with($plug);    # or confess "Could not load Plugin: '$plugin'\n";
    }

    return;
}

sub log {
    my ($self, $host, $log) = @_;

    return unless $log;

    my $name;
    given ($host) {
        when (ref $host eq 'Net::OpenSSH') { $name = $host->get_host; }
        default { $name = $host; }
    }
    chomp($log);
    print STDERR "[" . $name . "] " . $log . $/;

    return;
}

sub notify {
    my ($self, $ssh, $conf) = @_;
    # load notify plugin
    $self->load_plugin($self->notifyer);
    $self->send_notify($ssh, $conf);
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
