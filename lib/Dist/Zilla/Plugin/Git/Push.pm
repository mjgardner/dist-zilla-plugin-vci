package Dist::Zilla::Plugin::Git::Push;
use strict;
use Modern::Perl;
use utf8;

# VERSION
use Git::Wrapper;
use Moose;
use MooseX::Has::Sugar;
use MooseX::Types::Moose qw{ ArrayRef Str };

with 'Dist::Zilla::Role::AfterRelease';
with 'Dist::Zilla::Role::Git::Repo';

sub mvp_multivalue_args { return 'push_to' }

# -- attributes

has push_to => (
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    lazy    => 1,
    default => sub { [qw(origin)] },
);

sub after_release {
    my $self = shift;
    my $git  = Git::Wrapper->new( $self->repo_root );

    # push everything on remote branch
    for my $remote ( @{ $self->push_to } ) {
        $self->log("pushing to $remote");
        my @remote = split( /\s+/, $remote );
        $self->log_debug($_) for $git->push(@remote);
        $self->log_debug($_) for $git->push( { tags => 1 }, $remote[0] );
    }
    return;
}

1;

# ABSTRACT: push current branch

=for Pod::Coverage
    after_release
    mvp_multivalue_args

=head1 SYNOPSIS

In your F<dist.ini>:

    [Git::Push]
    push_to = origin      ; this is the default
    push_to = origin HEAD:refs/heads/released ; also push to released branch


=head1 DESCRIPTION

Once the release is done, this plugin will push current git branch to
remote end, with the associated tags.


The plugin accepts the following options:

=over 4

=item *

push_to - the name of the a remote to push to. The default is F<origin>.
This may be specified multiple times to push to multiple repositories.

=back
