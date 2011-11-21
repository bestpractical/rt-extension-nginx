use 5.008003;
use strict;
use warnings;

package RT::Extension::Nginx;

our $VERSION = '0.01';

use File::Spec;
use File::Path qw(make_path);
use autodie;

=head1 NAME

RT::Extension::Nginx - build a 

=head1 DESCRIPION

=cut

sub RootPath { return (shift)->CreateVarDir }
sub FcgiTempPath { return (shift)->CreateVarDir('fcgi.temp') }
sub FcgiStoragePath { return (shift)->CreateVarDir('fcgi.storage') }

sub NginxConfigPath {
    return File::Spec->catfile( (shift)->RootPath, 'nginx.conf' );
}

sub CreateVarDir {
    my $self = shift;
    my $path = File::Spec->catdir( $RT::VarPath, 'nginx', @_ );
    make_path( $path );
    return $path;
}

sub SetupRights {
    my $self = shift;

    my ($wuid, $wgid) = ( ($self->GetWebUser)[0], ($self->GetWebGroup)[0] );
    my ($rtuid, $rtgid) = (stat $RT::EtcPath)[4, 5];

    my $root = $self->RootPath;

    chmod 0400, map File::Spec->catfile($root, $_), $self->Templates;
    chown $rtuid, $rtgid, map File::Spec->catfile($root, $_), $self->Templates;

    chmod 0770, $self->FcgiTempPath, $self->FcgiStoragePath;
    chown $wuid, $wgid, $self->FcgiTempPath, $self->FcgiStoragePath;

    chmod 0755, $self->RootPath;
    chown $rtuid, $rtgid, $self->RootPath;
}

sub Templates {
    return qw(nginx.conf rt.server.conf fcgi.include.conf mime.types);
}

sub FindExecutable {
    my $self = shift;
    my $name = shift;

    foreach my $dir ( File::Spec->path ) {
        my $file = File::Spec->catfile( $dir, $name );
        return $file if -e $file && -x _;
    }
    return undef;
}

sub GetWebUser {
    my $self = shift;
    my $id = (stat $RT::MasonDataDir)[4];
    return ($id, getpwuid $id);
}

sub GetWebGroup {
    my $self = shift;
    my $id = (stat $RT::MasonDataDir)[5];
    return ($id, getgrgid $id);
}

sub GetSystemUser {
    my $self = shift;
    return ($>, getpwuid $>);
}

sub GenerateFile {
    my $self = shift;
    my $name = shift;
    my $stash = shift;

    require RT::Plugin;
    my $from = RT::Plugin->new( name => 'RT::Extension::Nginx' )->Path('etc');

    return $self->ParseTemplate(
        From  => [$from, $name],
        To    => [$stash->{'nginx_root'}, $name],
        Stash => $stash,
    );
}

sub ParseTemplate {
    my $self = shift;
    my %args = @_;

    $_ = File::Spec->catfile(@$_) foreach grep ref $_, $args{'From'}, $args{'To'};

    use Text::Template;
    my $template = Text::Template->new(
        TYPE       => 'FILE',
        SOURCE     => $args{'From'},
        DELIMITERS => [qw(<% %>)],
        PREPEND    => 'use warnings;',
    );
    my $res = $template->fill_in( HASH => { stash => $args{'Stash'} } );
    return $res unless $args{'To'};

    open my $fh, '>', $args{'To'};
    print $fh $res;
    close $fh;

    return $res;
}


=head1 AUTHOR

Ruslan Zakirov E<lt>ruz@bestpractical.comE<gt>

=head1 LICENSE

Under the same terms as perl itself.

=cut

1;
