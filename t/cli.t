use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Cwd qw(abs_path);

plan skip_all => 'Source CLI smoke test uses the ordinary server account' unless $>;
my $cli = abs_path('script/mogura');
local $ENV{HOME} = tempdir(CLEANUP => 1);
local $ENV{XDG_STATE_HOME} = "$ENV{HOME}/state";
chdir $ENV{HOME} or die $!;
for my $case (['--version', qr/^Mogura \d/], ['--help', qr/mogura server/]) {
    open my $out, '-|', $cli, $case->[0] or die "Run CLI: $!";
    local $/;
    like(<$out>, $case->[1], "$case->[0] via executable shebang");
    ok(close($out), 'CLI exits successfully');
}
ok(!-e $ENV{XDG_STATE_HOME}, 'Help and version leave no application state');
done_testing;
