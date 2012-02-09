package Giovanni::Plugins::Git;

use Mouse::Role;
use Git::Repository;

has 'git' => (
    is      => 'rw',
    isa     => 'Git::Repository',
    lazy    => 1,
    default => sub { Git::Repository->new(work_tree => $_[0]->repo) },
);

sub tag {
    my $self = shift;

    my $tag = 'v' . time;
    my $log =
        $self->git->run(tag => '-a', $tag, '-m', "tagging to $tag for rollout");
    $self->log('git', "Tag: [$tag] " . $log) if $self->is_debug;
    $log = $self->git->run('pull') unless $self->is_debug;
    $self->log('git', "Pull: " . $log) if $self->is_debug;
    $log = $self->git->run(push => 'origin', '--tags') unless $self->is_debug;
    $self->log('git', "Push: " . $log) if $self->is_debug;
    $self->version($tag);
    $self->log('git', $log);

    return $tag;
}

sub get_last_tag {
    my ($self, $n) = @_;

    $n = 1 unless $n;
    my @tags = $self->git->run('tag');
    $self->log('git', "Tags: " . join(', ', @tags) . $/) if $self->is_debug;

    return splice(@tags, $n - 1, $n);
}

around 'update_cache' => sub {
    my ($orig, $self, $ssh, $conf) = @_;

    my $log;
    my $cache_dir = $self->_get_cache_dir($conf);
    if ($self->config->{cache}) {
        if ($ssh->test("[ -d " . $cache_dir . " ]")) {
            $log .= $ssh->capture("cd $cache_dir && git pull");
            $self->log("running git pull ...");
        }
        else {
            $log = $ssh->capture("mkdir -p " . $self->config->{cache})
                unless $ssh->test("[ -d " . $self->config->{cache} . " ]");
            $log .= $ssh->capture(
                "git clone " . $self->config->{repo} . " $cache_dir");
            $self->log("running git clone ...");
        }
    }
    $self->log($ssh, $log);

    return;
};

around 'checkout' => sub {
    my ($orig, $self, $ssh, $conf) = @_;

    my $log;
    my $cache_dir = $self->_get_cache_dir($conf);
    if ($self->config->{deploy_dir}) {
        $log .=
            $ssh->capture("cd "
                . $self->config->{deploy_dir}
                . " && git clone --depth 1 --no-hardlinks file://"
                . $cache_dir
                . " .");
    }
    $self->log($ssh, $log);
};

sub _get_cache_dir {
    my ($self, $conf) = @_;
    my @parts = split(/\//, $self->config->{repo});
    my $git_dir = pop(@parts);
    return join('/', $self->config->{cache}, $git_dir);
}

1;
