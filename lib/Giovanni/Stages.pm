package Giovanni::Stages;

use Mouse;
use Expect;

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
    return;
}

sub rollout_timestamped {
    my ($self, $ssh, $conf) = @_;

    my $deploy_dir = join('/', $conf->{root}, 'current', time);
    my $log = $ssh->capture("mkdir -p ".$deploy_dir);
    $conf->{root} = $deploy_dir;
    print "[".$ssh->get_host."] running rollout_timestamped task ...\n";
    $self->logger($ssh, $log);
    $self->checkout($ssh, $conf);
    return;
}

sub restart {
    my ($self, $ssh, $conf) = @_;
    my ( $pty, $pid ) = $ssh->open2pty("sudo ".$conf->{init}." restart");
    my $exp = Expect->init($pty);
    my $ret = $exp->interact();
    print "[".$ssh->get_host."] running restart task ...\n";
    #$self->logger($ssh, $log);
    return;
}

sub checkout {
    my ($self, $ssh, $conf) = @_;
    print "[".$ssh->get_host."] running checkout task ...\n";
    return;
}


sub restart_phased {
    my ($self, $ssh, $conf) = @_;
    my ( $pty, $pid ) = $ssh->open2pty("sudo ".$conf->{init}." restart");
    my $exp = Expect->init($pty);
    $exp->interact();
    print "[".$ssh->get_host."] running restart_phased task ...\n";
    #$self->logger($ssh, $log);
    return;
}

sub notify {
    my ($self, $ssh, $conf) = @_;
    print "[".$ssh->get_host."] running notify task ...\n";
    return;
}

__PACKAGE__
