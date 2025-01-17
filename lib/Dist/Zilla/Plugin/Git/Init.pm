package Dist::Zilla::Plugin::Git::Init;
use strict;
use Modern::Perl;
use utf8;

# VERSION

our %transform = (    ## no critic (Variables::ProhibitPackageVars)
    lc  => sub { lc shift },
    uc  => sub { uc shift },
    q{} => sub {shift},
);
use String::Formatter method_stringf => {
    -as   => '_format_string',
    codes => {
        n => sub {"\n"},
        N => sub { $transform{ $_[1] || '' }->( $_[0]->zilla->name ) },
    },
};

use Git::Wrapper;
use Moose;
use MooseX::Has::Sugar;
use MooseX::Types::Moose qw(ArrayRef Str);
with 'Dist::Zilla::Role::AfterMint';

has commit_message => ( ro, isa => Str, default => 'initial commit' );
has [qw(remotes config_entries)] =>
    ( ro, isa => ArrayRef [Str], default => sub { [] } );

sub mvp_multivalue_args { return qw(config_entries remotes) }
sub mvp_aliases { return { config => 'config_entries', remote => 'remotes' } }

sub after_mint {
    my $self      = shift;
    my $mint_root = shift->{mint_root};

    my $git = Git::Wrapper->new($mint_root);
    $self->log("Initializing a new git repository in $mint_root");
    $git->init;

    ## no critic (Subroutines::ProhibitCallsToUndeclaredSubs)
    foreach my $config_spec ( @{ $self->config_entries } ) {
        my ( $option, $value ) = split q{ },
            _format_string( $config_spec, $self ), 2;
        $self->log_debug("Configuring $option $value");
        $git->config( $option, $value );
    }

    $git->add($mint_root);
    $git->commit(
        { message => _format_string( $self->commit_message, $self ) } );
    foreach my $remote_spec ( @{ $self->remotes } ) {
        my ( $remote, $url ) = split q{ },
            _format_string( $remote_spec, $self ), 2;
        $self->log_debug("Adding remote $remote as $url");
        $git->remote( add => $remote, $url );
    }
    return;
}

1;

# ABSTRACT: initialize git repository on dzil new

=for Pod::Coverage
    after_mint mvp_aliases mvp_multivalue_args


=head1 SYNOPSIS

In your F<profile.ini>:

    [Git::Init]
    commit_message = initial commit  ; this is the default
    remote = origin git@github.com:USERNAME/%{lc}N.git ; no default
    config = user.email USERID@cpan.org  ; there is no default

=head1 DESCRIPTION

This plugin initializes a git repository when a new distribution is
created with C<dzil new>.


=head2 Plugin options

The plugin accepts the following options:

=over 4

=item * commit_message - the commit message to use when checking in
the newly-minted dist. Defaults to C<initial commit>.

=item * config - a config setting to make in the repository.  No
config entries are made by default.  A setting is specified as
C<OPTION VALUE>.  This may be specified multiple times to add multiple entries.

=item * remote - a remote to add to the repository.  No remotes are
added by default.  A remote is specified as C<NAME URL>.  This may be
specified multiple times to add multiple remotes.

=back

=head2 Formatting options

You can use the following codes in C<commit_message>, C<config>, or C<remote>:

=over 4

=item C<%n>

A newline.

=item C<%N>

The distribution name.  You can also use C<%{lc}N> or C<%{uc}N> to get
the name in lower case or upper case, respectively.

=back
