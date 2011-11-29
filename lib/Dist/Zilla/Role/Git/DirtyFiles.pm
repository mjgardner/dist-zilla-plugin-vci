use 5.008;
use strict;
use warnings;
use utf8;
use Modern::Perl;

package Dist::Zilla::Role::Git::DirtyFiles;
# ABSTRACT: provide the allow_dirty & changelog attributes
# VERSION

use Moose::Role;
use Moose::Autobox;
use MooseX::Has::Sugar;
use MooseX::Types::Moose qw{ ArrayRef Str };

use List::Util 'first';

# -- attributes

=attr allow_dirty

A list of files that are allowed to be dirty in the git checkout.
Defaults to C<dist.ini> and the changelog (as defined per the
C<changelog> attribute.

=attr changelog

The name of the changelog. Defaults to C<Changes>.

=cut

has allow_dirty => (
  ro, lazy,
  isa     => ArrayRef[Str],
  builder => '_build_allow_dirty',
);
has changelog => ( ro, isa=>Str, default => 'Changes' );

around mvp_multivalue_args => sub {
  my ($orig, $self) = @_;

  my @start = $self->$orig;
  return (@start, 'allow_dirty');
};

# -- builders & initializers

sub _build_allow_dirty { [ 'dist.ini', shift->changelog ] }



=method list_dirty_files

  my @dirty = $plugin->list_dirty_files($git, $listAllowed);

This returns a list of the modified or deleted files in C<$git>,
filtered against the C<allow_dirty> attribute.  If C<$listAllowed> is
true, only allowed files are listed.  If it's false, only files that
are not allowed to be dirty are listed.

In scalar context, returns the number of dirty files.

=cut

sub list_dirty_files
{
  my ($self, $git, $listAllowed) = @_;

  my @allowed = map { qr/${_}$/ } $self->allow_dirty->flatten;

  return grep { 
      my $file = $_; 
      if ( first { $file =~ $_ } @allowed ) { 
          $listAllowed 
      } else { 
          !$listAllowed 
      } 
  } $git->ls_files( { modified=>1, deleted=>1 } );
} # end list_dirty_files


no Moose::Role;
no MooseX::Has::Sugar;
1;
__END__

=for Pod::Coverage
    mvp_multivalue_args

=head1 DESCRIPTION

This role is used within the git plugin to work with files that are
dirty in the local git checkout.
