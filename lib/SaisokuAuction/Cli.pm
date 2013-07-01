use strict;
use warnings;
use utf8;
 
package SaisokuAuction::Cli;
use Mojo::Base 'Mojolicious::Command';

use SaisokuAuction::Model;
 
use FindBin;
use File::Basename 'dirname';
use File::Spec::Functions qw(catdir splitdir);
 
sub development_mode {
  my $self = shift;
}
 
sub production_mode {
  my $self = shift;
}
 
sub setup {
  my $self = shift;
  my $app  = $self->app;
  my $mode = $app->mode;
 
  my $config = $self->app->plugin(
      'Config',
      { file => $self->rel_file('conf/yahooapi.conf') }
  );
  my $config_db = $self->app->plugin(
      'Config',
      { file => $self->rel_file('conf/db.conf') }
  );
  $self->attr( conf_api => sub { $config } );
  
  # Models
  $self->attr( model => sub { SaisokuAuction::Model->new( $config_db->{DB} ) });
  
  # setup each mode
  eval {
    my $method = "${mode}_mode";
    $self->$method;
  };
}

1;