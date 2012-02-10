package Giovanni::Plugins::Jabber;

use Mouse::Role;
use AnyEvent;
use AnyEvent::XMPP::Client;
use AnyEvent::XMPP::Ext::Disco;
use AnyEvent::XMPP::Ext::Version;
use AnyEvent::XMPP::Ext::MUC;
use AnyEvent::XMPP::Ext::MUC::Message;
use Data::Dumper;

around 'send_notify' => sub {
    my ( $orig, $self, $ssh ) = @_;

    print "notify via jabber\n";
    my $to = $self->config->{jabber_to};
    my $msg =
        'just ran a '
      . $self->config->{command} . ' for '
      . $self->config->{project} . ' on '
      . $self->config->{hosts};
    my $cnf = 1 if ( $to =~ m{conference} );

    my $j = AnyEvent->condvar;
    my $cl = AnyEvent::XMPP::Client->new();

    my ( $disco, $version, $muc, $muc_msg ) if $cnf;

    if ($cnf) {
        $disco   = AnyEvent::XMPP::Ext::Disco->new;
        $version = AnyEvent::XMPP::Ext::Version->new;
        $muc     = AnyEvent::XMPP::Ext::MUC->new( disco => $disco );
        $muc_msg = AnyEvent::XMPP::Ext::MUC::Message->new(
            type => 'groupchat',
            to   => $to,
            body => $msg
        );
        $cl->set_presence( undef, 'Giovanni is talking now.', 1 );
    }
    $cl->add_account( $self->config->{jabber_user}, $self->config->{jabber_pass} );

    $cl->reg_cb(
        session_ready => sub {
            my ( $cl, $acc ) = @_;
            if ($cnf) {
                $muc->join_room( $acc->connection, $to, 'Giovanni' );
                $muc_msg->{connection} = $acc->connection,
                $muc_msg->{room} = $muc->get_room( $acc->connection, $to );
                $muc_msg->send();
            }
            else {
                $cl->send_message(
                    $msg => $to,
                    undef, 'chat'
                );
            }
        },
        presence_update => sub {
            my ( $cl, $acc ) = @_;
            $cl->disconnect;
        },
        disconnect => sub {
            my ( $cl, $acc, $h, $p, $reas ) = @_;
            $j->broadcast;
        },
        error => sub {
            my ( $cl, $acc, $err ) = @_;
            print "ERROR: " . $err->string . "\n";
        },
    );
    $cl->start;
    $j->wait;
};

1;
