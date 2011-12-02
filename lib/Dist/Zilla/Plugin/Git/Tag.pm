package Dist::Zilla::Plugin::Git::Tag;
use strict;
use Modern::Perl;
use utf8;

# VERSION
use Git::Wrapper;
sub _format_tag;
use String::Formatter method_stringf => {
    -as   => '_format_tag',
    codes => {
        d => sub {
            require DateTime;
            DateTime->now( time_zone => $_[0]->time_zone )
                ->format_cldr( $_[1] || 'dd-MMM-yyyy' );
        },
        n => sub {"\n"},
        N => sub { $_[0]->zilla->name },
        t => sub {
            $_[0]->zilla->is_trial
                ? ( defined $_[1] ? $_[1] : '-TRIAL' )
                : q{};
        },
        v => sub { $_[0]->zilla->version },
    },
};

use Moose;
use MooseX::Has::Sugar;
use MooseX::Types::Moose qw(Bool Str);
with qw(
    Dist::Zilla::Role::BeforeRelease
    Dist::Zilla::Role::AfterRelease
    Dist::Zilla::Role::Git::Repo
);

# -- attributes

my %attr = (
    tag_format  => 'v%v',
    tag_message => 'v%v',
    time_zone   => 'local',
);
while ( my ( $name, $default ) = each %attr ) {
    has $name => ( ro, isa => Str, default => $default );
}

has signed => ( ro, isa => Bool, default   => 0 );
has branch => ( ro, isa => Str,  predicate => 'has_branch' );
has tag => ( ro, lazy,
    isa     => Str,
    default => sub { _format_tag( $_[0]->tag_format, $_[0] ) },
);

# -- role implementation

sub before_release {
    my $self = shift;

    my $git = Git::Wrapper->new( $self->repo_root );

    # Make sure a tag with the new version doesn't exist yet:
    my $tag = $self->tag;
    if ( $git->tag( -l => $tag ) ) {
        $self->log_fatal("tag $tag already exists");
    }
    return;
}

sub after_release {
    my $self = shift;
    my $git  = Git::Wrapper->new( $self->repo_root );

    # Make an annotated tag if tag_message, lightweight tag otherwise
    # make a GPG-signed tag
    my @opts = (
        $self->tag_message
        ? ( -m => _format_tag( $self->tag_message, $self ) )
        : (),
        $self->signed ? '-s' : (),
    );

    my @branch = $self->has_branch ? ( $self->branch ) : ();

    # create a tag with the new version
    my $tag = $self->tag;
    $git->tag( @opts, $tag, @branch );
    $self->log("Tagged $tag");
    return;
}

1;

# ABSTRACT: tag the new version

=for Pod::Coverage
    after_release
    before_release


=head1 SYNOPSIS

In your F<dist.ini>:

    [Git::Tag]
    tag_format  = v%v       ; this is the default
    tag_message = v%v       ; this is the default

=head1 DESCRIPTION

Once the release is done, this plugin will record this fact in git by
creating a tag.  By default, it makes an annotated tag.  You can set
the C<tag_message> attribute to change the message.  If you set
C<tag_message> to the empty string, it makes a lightweight tag.

It also checks before the release to ensure the tag to be created
doesn't already exist.  (You would have to manually delete the
existing tag before you could release the same version again, but that
is almost never a good idea.)


=head2 Plugin options

The plugin accepts the following options:

=over 4

=item * tag_format - format of the tag to apply. Defaults to C<v%v>, see
C<Formatting options> below.

=item * tag_message - format of the tag annotation. Defaults to C<v%v>,
see C<Formatting options> below. Use C<tag_message = > to create a
lightweight tag.

=item * time_zone - the time zone to use with C<%d>.  Can be any
time zone name accepted by DateTime.  Defaults to C<local>.

=item * branch - which branch to tag. Defaults to current branch.

=item * signed - whether to make a GPG-signed tag, using the default
e-mail address' key. Consider setting C<user.signingkey> if C<gpg>
can't find the correct key:

    $ git config user.signingkey 450F89EC

=back


=head2 Formatting options

Some plugin options allow you to customize the tag content. You can use
the following codes at your convenience:

=over 4

=item C<%{dd-MMM-yyyy}d>

The current date.  You can use any CLDR format supported by
L<DateTime|DateTime>. A bare C<%d> means C<%{dd-MMM-yyyy}d>.

=item C<%n>

A newline

=item C<%N>

The distribution name

=item C<%{-TRIAL}t>

Expands to -TRIAL (or any other supplied string) if this is a trial
release, or the empty string if not.  A bare C<%t> means C<%{-TRIAL}t>.

=item C<%v>

The distribution version

=back

=method tag

    my $tag = $plugin->tag;

Return the tag that will be / has been applied by the plugin. That is,
returns C<tag_format> as completed with the real values.
