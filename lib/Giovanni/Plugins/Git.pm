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
    $self->version($tag);
    $self->logger('localhost', $log);
    return $tag;
}

sub get_last_tag {
    my ( $self, $n ) = @_;

    $n = 1 unless $n;
    my @tags = $self->git->run('tag');
    print STDERR "Tags: " . join( ', ', @tags ) . "\n" if $self->is_debug;
    return splice( @tags, $n-1, $n );
}

around 'update_cache' => sub {
    my ($orig, $self, $ssh, $conf) = @_;

    my $log;
    my $cache_dir = $self->_get_cache_dir($conf);
    if($conf->{cache}){
        if($ssh->test("[ -d ".$cache_dir." ]")){
            $log .= $ssh->capture("cd $cache_dir && git pull" );
            print "[".$ssh->get_host."] running git pull ...\n";
        }else{
            $log = $ssh->capture("mkdir -p ".$conf->{cache})
                unless $ssh->test("[ -d ".$conf->{cache}." ]");
            $log .= $ssh->capture("git clone ".$conf->{repo}." $cache_dir" );
            print "[".$ssh->get_host."] running git clone ...\n";
        }
    }
    $self->logger($ssh, $log);
    return;
};

around 'checkout' => sub  {
    my ($orig, $self, $ssh, $conf) = @_;
    my $log;
    my $cache_dir = $self->_get_cache_dir($conf);
    if($conf->{root}){
        $log .= $ssh->capture("cd ".$conf->{root}." && git clone --depth 1 --no-hardlinks file://".$cache_dir." ." );
    } 
    $self->logger($ssh, $log);
};

sub _get_cache_dir {
    my ($self, $conf) = @_;
    my @parts = split(/\//, $conf->{repo});
    my $git_dir = pop(@parts);
    return join('/', $conf->{cache}, $git_dir);
}

__PACKAGE__
