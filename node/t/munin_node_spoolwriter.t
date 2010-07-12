# vim: sw=4 : ts=4 : et
use warnings;
use strict;

use Test::More tests => 15;
use Test::LongString;

use POSIX ();
use File::Temp qw( tempdir );
use Data::Dumper;
use File::Slurp;

use Munin::Node::SpoolWriter;


### new
{
    my $dir = POSIX::getcwd();

    my $writer = new_ok('Munin::Node::SpoolWriter' => [
        spooldir => $dir,
    ], 'spooldir provided to constructor');

    is($writer->{spooldir}, $dir, 'spooldir key is set');
    ok( -d $writer->{spooldirhandle}, 'spooldirhandle refers to a directory');
}
{
    eval { Munin::Node::SpoolWriter->new(fnord => 'blort') };
    like($@, qr/./, 'Dies if no spooldir provided');
}


### write
{
    my $dir = tempdir( CLEANUP => 1 );
    my $writer = Munin::Node::SpoolWriter->new(spooldir => $dir);

    $writer->write(1234567890, 'fnord', [
        'graph_title CPU usage',
        'graph_order system user nice idle iowait irq softirq',
        'graph_args --base 1000 -r --lower-limit 0 --upper-limit 200',
        'update_rate 86400',
        'system.label system',
        'system.value 999999'
    ]);

    my $config_file = "$dir/munin-daemon.fnord.config";
    ok( -r $config_file, 'config spool file is readable');

    my $config = read_file($config_file);
    is_string($config, <<EOC, 'Config was written correctly');
graph_title CPU usage
graph_order system user nice idle iowait irq softirq
graph_args --base 1000 -r --lower-limit 0 --upper-limit 200
update_rate 86400
system.label system
EOC

    my $data_file = "$dir/munin-daemon.fnord.data";
    ok( -r $data_file, 'data spool file is readable');

    my $data = read_file($data_file);
    is_string($data, <<EOC, 'Data was written correctly');
system.value 1234567890:999999
EOC


### Now a different set of data
    $writer->write(1234567891, 'fnord', [
        'graph_title CPU usage!',  # this line is different
        'graph_order system user nice idle iowait irq softirq',
        'graph_args --base 1000 -r --lower-limit 0 --upper-limit 200',
        'update_rate 86400',
        'system.label system',
        'system.value 999998'
    ]);

    $config = read_file($config_file);
    is_string($config, <<EOC, 'Config was replaced');
graph_title CPU usage!
graph_order system user nice idle iowait irq softirq
graph_args --base 1000 -r --lower-limit 0 --upper-limit 200
update_rate 86400
system.label system
EOC

    $data = read_file($data_file);
    is_string($data, <<EOC, 'Data was appended to');
system.value 1234567890:999999
system.value 1234567891:999998
EOC

}
### writing different types of value.
{
    my @tests = (
        #  timestamp,    value,             expected
        [ 1234567890, '999999',   '1234567890:999999',   'Integer without timestamp'  ],
        [ 1234567890, 'U',        '1234567890:U',        'Unknown without timestamp'  ],
        [ 1234567890, '-2',       '1234567890:-2',       'Negative without timestamp' ],
        [ 1234567890, '3.141',    '1234567890:3.141',    'Float without timestamp'    ],
        [ 1234567890, '1.05e-34', '1234567890:1.05e-34', 'E-notation without timestamp'    ],
    );

    foreach (@tests) {
        my ($timestamp, $value, $expected, $msg) = @$_;

        my $dir = tempdir( CLEANUP => 1 );
        my $writer = Munin::Node::SpoolWriter->new(spooldir => $dir);

        $writer->write($timestamp, 'fnord', [
            'graph_title CPU usage',
            'system.label system',
            "system.value $value",
        ]);

        my $data_file = "$dir/munin-daemon.fnord.data";
        unless ( -r $data_file) {
            fail("$msg: File not created");
            next
        }

        my $data = read_file($data_file);
        is_string($data, "system.value $expected\n", $msg);
    }
}
