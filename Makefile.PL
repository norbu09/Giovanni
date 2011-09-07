use inc::Module::Install;

name     'Giovanni';
all_from 'lib/Giovanni.pm';
author   q{Lenz Gschwendtner <norbu09@cpan.org>};
license  'perl';

build_requires 'Test::More';

auto_install;

WriteAll;

