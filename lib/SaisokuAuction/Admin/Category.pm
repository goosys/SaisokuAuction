package SaisokuAuction::Admin::Category;
use Mojo::Base 'Mojolicious::Controller';

sub index {
  my $self = shift;
  
  my $rows = $self->app->model->search(
    'categories',
    {
      'site_id' => $self->param('id')
    },
    {
      'limit' => 50,
      'order_by' => [ 'order_number','id' ],
    }
  );
  
  $self->stash('rows' => $rows);
  $self->render(template=>'admin/category/index');
}

sub create {
  my $self = shift;
  
  my $id;
  my $param = {
    site_id  => $self->param('site_id') || $self->param('parent_id'),
    basename => $self->param('basename') || '',
    title    => $self->param('title') || '',
    alert_subject => $self->param('alert_subject') || '',
    order_number => $self->param('order_number') ||1,
  };
  
  if (uc $self->req->method eq 'POST') {
    if( $self->param('id') ){
      $id = $self->param('id');
      $self->app->model->update('categories',$param,{ id=>$id });
    }else{
      my $row = $self->app->model->insert('categories',$param);
      $id = $row->id;
    }
  
  } else {
    $param->{id} = undef;
    my $row = $self->app->model->find_or_new('categories', $param );
    $self->stash('row' => $row);
    $self->render(template=>'admin/category/view');
    return;
  }
  
  $self->redirect_to('admin/category/view/'.$id);
}

sub delete {
  my $self = shift;
  
  my $row = $self->app->model->single(
    'categories',
    { id => $self->param('id') },
  );
  if( $row->delete ) { 
    $self->stash('alert' => { status=>'success', message=>'deleted #'.$self->param('id')});
    
  } else {
    $self->stash('alert' => { status=>'error', message=>'failed delete #'.$self->param('id')});
  }
  
  $self->redirect_to('admin/category/'.$row->site_id);
}

sub view {
  my $self = shift;
  
  my $row = $self->app->model->single(
    'categories',
    { id => $self->param('id') },
  );
  
  $self->stash('row' => $row);
  $self->render(template=>'admin/category/view');
}

1;
