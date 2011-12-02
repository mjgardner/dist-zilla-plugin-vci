package Dist::Zilla::Role::Git::Repo;
use Modern::Perl;
use utf8;

# VERSION
use Moose::Role;
use MooseX::Has::Sugar;
use MooseX::Types::Moose 'Str';

has repo_root => ( ro, isa => Str, default => q{.} );

1;

# ABSTRACT: Provide repository information for Git plugins

=head1 DESCRIPTION

This role is used within the git plugin to get information about the
repository structure.

=attr repo_root

The repository root, either as a full path or relative to the distribution
root. Default is C<.> (the current directory).
