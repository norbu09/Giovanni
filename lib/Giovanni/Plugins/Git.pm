package Giovanni::Plugins::Git;

use Mouse::Role;
use Git::Repository;

has 'git' => (
    is      => 'rw',
    isa     => 'Git::Repository',
    lazy    => 1,
    default => sub { Git::Repository->new( work_tree => $_[0]->repo ) },
);

sub tag {
    my $self = shift;

    my $tag = 'v' . time;
    my $log =
      $self->git->run( tag => '-a', $tag, '-m', "tagging to $tag for rollout" );
    print STDERR "Tag: [$tag] " . $log . "\n" if $self->is_debug;
    $log = $self->git->run('pull') unless $self->is_debug;
    print STDERR "Pull: " . $log . "\n" if $self->is_debug;
    $log = $self->git->run( push => 'origin', '--tags' ) unless $self->is_debug;
    print STDERR "Push: " . $log . "\n" if $self->is_debug;
    return $tag;
}

sub get_last_tag {
    my ( $self, $n ) = @_;

    $n = 1 unless $n;
    my @tags = $self->git->run('tag');
    print STDERR "Tags: " . join( ', ', @tags ) . "\n" if $self->is_debug;
    return splice( @tags, $n-1, $n );
}

__PACKAGE__
