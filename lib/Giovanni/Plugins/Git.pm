package Giovanni::Plugins::Git;

use Mouse::Role;
use Git::Repository;

sub tag {
    my $self = shift;
    my $git = Git::Repository->new(work_tree => $self->repo);
}
