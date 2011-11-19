use inc::Module::Install;

RTx('RT-Extension-Nginx');
all_from('lib/RT/Extension/Nginx.pm');
readme_from('lib/RT/Extension/Nginx.pm');

# XXX: This should be reported by M::I::RTx
my ($lib_path) = $INC{'RT.pm'} =~ /^(.*)[\\\/]/;
my $local_lib_path = "$RT::LocalPath/lib";
unshift @INC, $local_lib_path, $lib_path;

substitute( {
        RT_LIB_PATH => join( ' ', $local_lib_path, $lib_path ),
    },
    'sbin/rt-generate-nginx-conf',
);

requires 'autodie';
requires 'Text::Template' => 1.20;

