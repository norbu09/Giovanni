package Giovanni::Stages;

use Mouse;

# Stages are defined here and expected to be overridden with plugins.
# the idea is to have different plugins that can extend the existing
# stages real easy. If this stages approach turns out to be too limited
# (ie 1000s of stages in one file, not a good look) we may need to
# rethink this approach.

sub update_scm {
    my ($self, $ssh, $conf) = @_;
    print "[".$ssh->get_host."] running update_scm task ...\n";
    return;
}

sub rollout {
    my ($self, $ssh, $conf) = @_;
    print "[".$ssh->get_host."] running rollout task ...\n";
    return;
}

sub rollout_timestamped {
    my ($self, $ssh, $conf) = @_;
    print "[".$ssh->get_host."] running rollout_timestamped task ...\n";
    return;
}

sub restart {
    my ($self, $ssh, $conf) = @_;
    print "[".$ssh->get_host."] running restart task ...\n";
    return;
}

sub restart_phased {
    my ($self, $ssh, $conf) = @_;
    print "[".$ssh->get_host."] running restart_phased task ...\n";
    return;
}

sub notify {
    my ($self, $ssh, $conf) = @_;
    print "[".$ssh->get_host."] running notify task ...\n";
    return;
}

__PACKAGE__
