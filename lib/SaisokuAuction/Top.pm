package SaisokuAuction::Top;
use Mojo::Base 'Mojolicious::Controller';

# This action will render a template
sub index {
  my $self = shift;
  
  my $entries = $self->app->model->search(
    'entries',
    {},
    {
      limit => 10,
      order_by => [
        { 'created_at' => 'DESC' },
      ],
    }
  );
  
  $self->render(
    {
      message => $self->flash('message') || 'Welcome to the Mojolicious real-time web framework!',
      entries => $entries,
    }
  );
}

1;
