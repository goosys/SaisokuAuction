package SaisokuAuction::Admin::Site;
use Mojo::Base 'Mojolicious::Controller';

sub index {
  my $self = shift;
  
  my $rows = $self->app->model->search(
    'sites',
    {},
    {
      'limit' => 10,
    }
  );
  
  $self->stash('rows' => $rows);
  $self->render(template=>'admin/site/index');
}

sub create {
  my $self = shift;
  
  my $id;
  my $param = {
    basename => $self->param('basename') || '',
    title    => $self->param('title') || '',
    order_number => $self->param('order_number') ||1,
  };
  
  if (uc $self->req->method eq 'POST') {
    if( $self->param('id') ){
      $id = $self->param('id');
      $self->app->model->update('sites',$param,{ id=>$id });
    }else{
      my $row = $self->app->model->insert('sites',$param);
      $id = $row->id;
    }
    
  } else {
    $param->{id} = undef;
    my $row = $self->app->model->find_or_new('sites', $param );
    $self->stash('row' => $row);
    $self->render(template=>'admin/site/view');
    return;
  }
  
  $self->redirect_to('admin/site/view/'.$id);
}

sub delete {
  my $self = shift;
  
  my $row = $self->app->model->single(
    'sites',
    { id => $self->param('id') },
  );
  if( $row->delete ) { 
    $self->stash('alert' => { status=>'success', message=>'deleted #'.$self->param('id')});
    
  } else {
    $self->stash('alert' => { status=>'error', message=>'failed delete #'.$self->param('id')});
  }
  
  $self->redirect_to('admin/site/');
}

sub view {
  my $self = shift;
  
  my $row = $self->app->model->single(
    'sites',
    { id => $self->param('id') },
  );
  
  $self->stash('row' => $row);
  $self->render(template=>'admin/site/view');
}

1;
