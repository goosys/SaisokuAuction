package SaisokuAuction::Site;
use Mojo::Base 'Mojolicious::Controller';

# This action will render a template
sub index {
  my $self = shift;
  my $sitename = $self->param('sitename');
  my $page     = $self->param('page') || 1;
  
  my $site = $self->app->model->single(
    'sites',
    {
      'basename' => $sitename
    },
  );
  
  my $rs = $self->app->model->resultset(
    {
      select => [q/SQL_CALC_FOUND_ROWS entries.*/],
    }
  );
  
  if( $site ) {
    $rs->from([]);
    $rs->add_join(
      #select * from entries as e inner join categories as c on e.category_id = c.id ;
      entries => [
        {
          type  => 'inner',
          table => 'categories',
          condition => 'categories.id = entries.category_id',
        },
      ],
    );
    $rs->add_where( 'categories.site_id' => $site->id );
    $rs->order({ 'column' => 'created_at desc'  });
    $rs->limit( 3 );
    $rs->offset( 3 * ( $page - 1) );
    $self->stash('site', $site);
    
  } else {
    $rs->from(['entries']);
    $rs->add_where( 'id' => 1 );
    
  }
  my $entries = $rs->retrieve;
  my $rows    = $self->app->model->search_by_sql('SELECT FOUND_ROWS() AS row')->first;
  
  $self->stash('entries', $entries);
  $self->stash('pager'  , { rows => $rows, limit=>3, current_page=> $page });
  $self->render();
  
}

1;
