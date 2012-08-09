package Giovanni::Plugins::HipChat;

use Mouse::Role;
use Data::Dumper;
use LWP::UserAgent;

around 'send_notify' => sub {
    my ( $orig, $self, $ssh ) = @_;

    print "notify via jabber\n";
    my @tos = split(/\s*,\s*/, $self->config->{hipchat_rooms});
    my $msg =
        'just ran a '
      . $self->config->{command} . ' for '
      . $self->config->{project} . ' on '
      . $ssh->get_host;
    my $ua = LWP::UserAgent->new();
    my $url = 'https://api.hipchat.com/v1/rooms/message?format=json&auth_token='.$self->config->{hipchat_token};
    foreach my $to (@tos){
        $ua->request(POST $url, {
            room_id => $to,
            from => 'Giovanni',
            message => $msg,
            message_format => 'text',
            notify => 1,
            color => 'green',
        });
    }
};

1;
