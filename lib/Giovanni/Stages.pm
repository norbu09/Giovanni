package Giovanni::Stages;

use Mouse;
use Expect;
use Data::Dumper;

# Stages are defined here and expected to be overridden with plugins.
# the idea is to have different plugins that can extend the existing
# stages real easy. If this stages approach turns out to be too limited
# (ie 1000s of stages in one file, not a good look) we may need to
# rethink this approach.

sub update_cache {
    my ($self, $ssh, $conf) = @_;
    print "[".$ssh->get_host."] running update_cache task ...\n";
    return;
}

sub rollout {
    my ($self, $ssh, $conf) = @_;
    print "[".$ssh->get_host."] running rollout task ...\n";
    my $log = $ssh->capture("mkdir -p ".$conf->{root});
    $self->logger($ssh, $log);
    $self->checkout($ssh, $conf);
    return;
}

sub rollout_timestamped {
    my ($self, $ssh, $conf) = @_;

    my $deploy_dir = join('/', $conf->{root}, 'releases', time);
    my $current = join('/', $conf->{root}, 'current');
    my $log = $ssh->capture("mkdir -p ".$deploy_dir);
    $log .= $ssh->capture("unlink ".$current."; ln -s ".$deploy_dir." ".$current);
    $conf->{root} = $deploy_dir;
    print "[".$ssh->get_host."] running rollout_timestamped task ...\n";
    $self->logger($ssh, $log);
    $self->checkout($ssh, $conf);
    return;
}

sub rollback_timestamped {
    my ($self, $ssh, $conf, $offset) = @_;
    my $deploy_dir = join('/', $conf->{root}, 'releases');
    my $current = join('/', $conf->{root}, 'current');
    print "[".$ssh->get_host."] running rollback task ...\n";
    my @rels = $ssh->capture("ls -1 ".$deploy_dir);
    @rels = sort(@rels);
    my $link = $ssh->capture("ls -l ".$current." | sed 's/^.*->\\s*//'");
    my @path = split(/\//, $link);
    my $current_rel = pop(@path);
    my (@past, @future);
    foreach my $rel (@rels){
        chomp($rel);
        next unless $rel =~ m{^\w};
        if($rel == $current_rel){
            push(@future, $rel);
            next;
        }
        if(@future){
            push(@future, $rel);
        } else {
            push(@past, $rel);
        }
    }
    $deploy_dir = join('/', $conf->{root}, pop(@past));
    my $log = $ssh->capture("unlink ".$current."; ln -s ".$deploy_dir." ".$current);
    $self->logger($ssh, $log);
    return;
}

sub rollback_scm {
    my ( $self, $ssh, $conf, $offset ) = @_;

    # load SCM plugin
    $self->load_plugin( $self->scm );
    my $tag = $self->get_last_tag($offset);
    print STDERR "Rolling back to tag: $tag\n" if $self->is_debug;
    # TODO change checkout to accept an optional tag so we can reuse it
    # here to check out an old version.
    return;
}

sub restart {
    my ($self, $ssh, $conf) = @_;
    my ( $pty, $pid ) = $ssh->open2pty("sudo ".$conf->{init}." restart");
    my $exp = Expect->init($pty);
    my $ret = $exp->interact();
    print "[".$ssh->get_host."] running restart task ...\n";
    $self->logger($ssh, "restarted ...");
    return;
}

sub checkout {
    my ($self, $ssh, $conf) = @_;
    print "[".$ssh->get_host."] running checkout task ...\n";
    return;
}

sub cleanup_timestamped {
    my ($self, $ssh, $conf, $offset) = @_;
    print STDERR "PATH: ".$conf->{root}."\n";
    if($conf->{root} =~ m{^.*/\d+$}){
        my @path = split(/\//, $conf->{root});
        pop(@path);
        pop(@path);
        $conf->{root} = join('/', @path);
    }
    print STDERR "PATH2: ".$conf->{root}."\n";
    my $deploy_dir = join('/', $conf->{root}, 'releases');
    my $current = join('/', $conf->{root}, 'current');
    print "[".$ssh->get_host."] running cleanup task ...\n";
    my @rels = $ssh->capture("ls -1 ".$deploy_dir);
    @rels = sort(@rels);
    my $link = $ssh->capture("ls -l ".$current." | sed 's/^.*->\\s*//'");
    my @path = split(/\//, $link);
    my $current_rel = pop(@path);
    my (@past, @future);
    foreach my $rel (@rels){
        chomp($rel);
        next unless $rel =~ m{^\w};
        if($rel == $current_rel){
            push(@future, $rel);
            next;
        }
        if(@future){
            push(@future, $rel);
        } else {
            push(@past, $rel);
        }
    }
    $deploy_dir = join('/', $conf->{root}, pop(@past));
    my $num = $conf->{keep_versions} || 5;
    my $log;
    while($#past > ($num)){
        my $to_del = join('/', $conf->{root}, 'releases', shift(@past));
        $log = $ssh->capture("rm -rf ".$to_del);
    }
    $self->logger($ssh, $log);
    return;
}

sub restart_phased {
    my ($self, $ssh, $conf) = @_;
    my ( $pty, $pid ) = $ssh->open2pty("sudo ".$conf->{init}." restart");
    my $exp = Expect->init($pty);
    $exp->interact();
    print "[".$ssh->get_host."] running restart_phased task ...\n";
    $self->logger($ssh, "restarted ...");
    return;
}

sub notify {
    my ($self, $ssh, $conf) = @_;
    print "[".$ssh->get_host."] running notify task ...\n";
    return;
}

__PACKAGE__
