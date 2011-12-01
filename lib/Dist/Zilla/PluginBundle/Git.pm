package Dist::Zilla::PluginBundle::Git;
use strict;
use Modern::Perl;
use utf8;

# VERSION
use Moose;
use Class::Load 'load_class';

with 'Dist::Zilla::Role::PluginBundle';

# bundle all git plugins
my @names = qw{ Check Commit Tag Push };

my %multi;
for my $name (@names) {
    my $class = "Dist::Zilla::Plugin::Git::$name";
    load_class($class);
    @multi{ $class->mvp_multivalue_args } = ();
}

sub mvp_multivalue_args { keys %multi; }

sub bundle_config {
    my ( $self, $section ) = @_;

    #my $class = ( ref $self ) || $self;
    my $arg = $section->{payload};

    my @config;

    for my $name (@names) {
        my $class = "Dist::Zilla::Plugin::Git::$name";
        my %payload;
        foreach my $k ( keys %$arg ) {
            $payload{$k} = $arg->{$k} if $class->can($k);
        }
        push @config, [ "$section->{name}/$name" => $class => \%payload ];
    }

    return @config;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

# ABSTRACT: all git plugins in one go

=for Pod::Coverage
    bundle_config
    mvp_multivalue_args

=head1 SYNOPSIS

In your F<dist.ini>:

    [@Git]
    changelog   = Changes             ; this is the default
    allow_dirty = dist.ini            ; see Git::Check...
    allow_dirty = Changes             ; ... and Git::Commit
    commit_msg  = v%v%n%n%c           ; see Git::Commit
    tag_format  = %v                  ; see Git::Tag
    tag_message = %v                  ; see Git::Tag
    push_to     = origin              ; see Git::Push


=head1 DESCRIPTION

This is a plugin bundle to load all git plugins. It is equivalent to:

    [Git::Check]
    [Git::Commit]
    [Git::Tag]
    [Git::Push]

The options are passed through to the plugins.
