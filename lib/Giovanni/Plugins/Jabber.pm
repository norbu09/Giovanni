package Giovanni::Plugins::Jabber;

use Mouse::Role;
use AnyEvent;
use AnyEvent::XMPP::Client;
use AnyEvent::XMPP::Ext::Disco;
use AnyEvent::XMPP::Ext::Version;
use AnyEvent::XMPP::Ext::MUC;
use AnyEvent::XMPP::Ext::MUC::Message;

around 'notify' => sub {
    my ( $orig, $self, $ssh, $conf ) = @_;

    my $to = $conf->{jabber_to};
    my $msg =
        'Giovanni just ran '
      . $conf->{command} . ' for '
      . $conf->{project} . ' on '
      . $conf->{hosts};
    my $cnf = 1 if ( $to =~ m{conference} );

    my $j = AnyEvent->condvar;
    my $cl = AnyEvent::XMPP::Client->new( debug => 1 );

    my ( $disco, $version, $muc, $muc_msg ) if $cnf;

    if ($cnf) {
        print "we are in conference more\n";
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
    $cl->add_account( $conf->{jabber_user}, $conf->{jabber_pass} );

    $cl->reg_cb(
        session_ready => sub {
            my ( $cl, $acc ) = @_;
            print "session ready\n";
            if ($cnf) {
                $muc->join_room( $acc->connection, $to, 'Giovanni' );
                $muc_msg->{connection} = $acc->connection,
                  print "setting room for\n";
                $muc_msg->{room} = $muc->get_room( $acc->connection, $to );
                print "Got muc message set up\n";
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
            print "presence update\n";
            $cl->disconnect;
        },
        disconnect => sub {
            my ( $cl, $acc, $h, $p, $reas ) = @_;
            print "disconnect ($h:$p): $reas\n";
            $j->broadcast;
        },
        error => sub {
            my ( $cl, $acc, $err ) = @_;
            print "ERROR: " . $err->string . "\n";
        },
        message => sub {
            my ( $cl, $acc, $msg ) = @_;
            print "message from: " . $msg->from . ": " . $msg->any_body . "\n";
        }
    );
    $cl->start;
    $j->wait;
};
