package Dist::Zilla::Plugin::Git::NextVersion;
use strict;
use Modern::Perl;
use utf8;

# VERSION
use Dist::Zilla 4 ();
use Git::Wrapper;
use English '-no_match_vars';
use Version::Next 'next_version';
use version 0.80 ();

use Moose;
use MooseX::Has::Sugar;
use MooseX::Types::Moose 'Str';
use namespace::autoclean 0.09;

with qw(Dist::Zilla::Role::VersionProvider Dist::Zilla::Role::Git::Repo);

# -- attributes

my %attr = ( version_regexp => '^v(.+)$', first_version => '0.001' );
while ( my ( $name, $default ) = each %attr ) {
    has $name => ( ro, isa => Str, default => $default );
}

# -- role implementation

sub provide_version {
    my $self = shift;

    # override (or maybe needed to initialize)
    return $ENV{V} if exists $ENV{V};

    local $INPUT_RECORD_SEPARATOR = "\n";
    my $git    = Git::Wrapper->new( $self->repo_root );
    my $regexp = $self->version_regexp;

    my @tags = $git->tag;
    {
        ## no critic (RegularExpressions::RequireDotMatchAnything)
        ## no critic (RegularExpressions::RequireExtendedFormatting)
        ## no critic (RegularExpressions::RequireLineBoundaryMatching)
        @tags = map { /$regexp/ ? $1 : () } @tags;
    }
    return $self->first_version if not @tags;

    # find highest version from tags
    my ($last_ver)
        = reverse sort { version->parse($a) <=> version->parse($b) }
        grep {
        ## no critic (ErrorHandling::RequireCheckingReturnValueOfEval)
        eval { version->parse($ARG) }
        } @tags;
    if ( !defined $last_ver ) {
        $self->log_fatal('Could not determine last version from tags');
    }

    my $new_ver = next_version($last_ver);
    $self->log("Bumping version from $last_ver to $new_ver");

    return $self->zilla->version("$new_ver");
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

# ABSTRACT: provide a version number by bumping the last git release tag

=for Pod::Coverage
    provide_version

=head1 SYNOPSIS

In your F<dist.ini>:

    [Git::NextVersion]
    first_version = 0.001       ; this is the default
    version_regexp  = ^v(.+)$   ; this is the default

=head1 DESCRIPTION

This does the
L<Dist::Zilla::Role::VersionProvider|Dist::Zilla::Role::VersionProvider> role.
It finds the last version number from your git tags, increments it using
L<Version::Next|Version::Next>, and uses the result as the C<version> parameter
for your distribution.

The plugin accepts the following options:

=over

=item *

C<first_version> - if the repository has no tags at all, this version
is used as the first version for the distribution.  It defaults to "0.001".

=item *

C<version_regexp> - regular expression that matches a tag containing
a version.  It must capture the version into $1.  Defaults to ^v(.+)$
which matches the default C<tag_format> from
L<Dist::Zilla::Plugin::Git::Tag|Dist::Zilla::Plugin::Git::Tag>.
If you change C<tag_format>, you B<must> set a corresponding C<version_regexp>.

=back

You can also set the C<V> environment variable to override the new version.
This is useful if you need to bump to a specific version.  For example, if
the last tag is 0.005 and you want to jump to 1.000 you can set V = 1.000.

  $ V=1.000 dzil release
