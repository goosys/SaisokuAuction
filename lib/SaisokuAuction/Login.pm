package SaisokuAuction::Login;
use Mojo::Base 'Mojolicious::Controller';

sub index {
  my $self = shift;
  
  $self->render();
}

sub login {
  my $self = shift;
  my ($u, $p) = ($self->param('email'), $self->param('password'));
  
  if ( $self->authenticate($u, $p) ) {
      $self->redirect_to( $self->req->url->base . '/admin/site' );
  }
  else{
     #$self->logout ;
     delete $self->session->{'auth_data'};
     $self->redirect_to( $self->req->url->base . '/login' );
  }

}

sub logout {
  my $self = shift;
  
  #$self->logout ;
  delete $self->session->{'auth_data'};
  $self->redirect_to( $self->req->url->base . '/login' );
}

1;
