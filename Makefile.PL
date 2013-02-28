use 5.010;
use inc::Module::Install;

name     'Giovanni';
all_from 'lib/Giovanni.pm';
author   q{Lenz Gschwendtner <norbu09@cpan.org>};
license  'perl';

build_requires 'Test::More';

requires 'Config::GitLike';
requires 'Mouse';
requires 'Mouse::Util';
requires 'Mouse::Role';
requires 'Getopt::Long';
requires 'Pod::Usage';
requires 'Expect';
requires 'Net::OpenSSH';
requires 'Sys::Hostname';
requires 'Git::Repository';
requires 'IO::Stty';
requires 'XML::Twig';
#requires 'AnyEvent';
#requires 'AnyEvent::XMPP::Client';
requires 'LWP::UserAgent';
requires 'LWP::Protocol::https';

auto_install;

install_script 'bin/gio';

WriteAll;

