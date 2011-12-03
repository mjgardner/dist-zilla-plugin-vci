package Dist::Zilla::Role::Git::DirtyFiles;
use strict;
use Modern::Perl;
use utf8;

# VERSION
use List::Util 'first';
use Moose::Role;
use Moose::Autobox;
use MooseX::Has::Sugar;
use MooseX::Types::Moose qw(ArrayRef Str);

# -- attributes

has changelog => ( ro, isa => Str, default => 'Changes' );
has allow_dirty => ( ro, lazy,
    isa => ArrayRef [Str],
    default => sub { [ 'dist.ini', shift->changelog ] },
);

around mvp_multivalue_args => sub {
    my ( $orig, $self ) = @_;

    my @start = $self->$orig;
    return ( @start, 'allow_dirty' );
};

sub list_dirty_files {
    my ( $self, $git, $list_allowed ) = @_;

    my @allowed = map {qr/ ${_} \z/xms} $self->allow_dirty->flatten;

    return grep {
        my $file = $_;
        ( first { $file =~ $_ } @allowed ) ? $list_allowed : !$list_allowed;
    } $git->ls_files( { modified => 1, deleted => 1 } );
}    # end list_dirty_files

no Moose::Role;
no MooseX::Has::Sugar;
1;

# ABSTRACT: provide the allow_dirty & changelog attributes

=for Pod::Coverage
    mvp_multivalue_args

=head1 DESCRIPTION

This role is used within the git plugin to work with files that are
dirty in the local git checkout.

=attr allow_dirty

A list of files that are allowed to be dirty in the git checkout.
Defaults to C<dist.ini> and the changelog (as defined per the
C<changelog> attribute.)

=attr changelog

The name of the changelog. Defaults to C<Changes>.

=method list_dirty_files

  my @dirty = $plugin->list_dirty_files($git, $list_allowed);

This returns a list of the modified or deleted files in C<$git>,
filtered against the C<allow_dirty> attribute.  If C<$list_allowed> is
true, only allowed files are listed.  If it's false, only files that
are not allowed to be dirty are listed.

In scalar context, returns the number of dirty files.
