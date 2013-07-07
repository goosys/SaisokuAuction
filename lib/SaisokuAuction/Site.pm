package SaisokuAuction::Site;
use Mojo::Base 'Mojolicious::Controller';

sub index {
  my $self = shift;
  my $sitename = $self->param('sitename');
  my $page     = $self->param('page') || 1;
  my $archive  = $self->param('archive') || 0;
  $self->app->plugin('SaisokuAuction::Helper::Pagination');
  my $page_limit = 5; 
  
  my $site = $self->app->model->single(
    'sites',
    {
      'basename' => $sitename
    },
  );
  
  my $rs = $self->app->model->resultset(
    {
      select => [q/SQL_CALC_FOUND_ROWS e.*, c.basename as category_basename, s.basename as site_basename/],
    }
  );
  
  {
    $rs->from([]);
    $rs->add_join(
      #select * from entries as e inner join categories as c on e.category_id = c.id ;
      'entries as e' => [
        {
          type  => 'inner',
          table => 'categories as c',
          condition => 'c.id = e.category_id',
        },
      ],
    );
    $rs->add_join(
      'c' => [
        {
          type  => 'inner',
          table => 'sites as s',
          condition => 's.id = c.site_id',
        },
      ],
    );
  }
  
  if( $site ) {
    $rs->add_where( 'c.site_id' => $site->id );
    $rs->add_where( 'c.basename' => $self->param('categoryname') ) if( $archive eq 'category' );
    $self->stash('site', $site);
    
  }
  
  {
    $rs->add_where( 'DATE_FORMAT(e.created_at,\'%Y%m\')' => join('',$self->param('year'),$self->param('month')) ) if( $archive eq 'monthly' );
    $rs->order({ 'column' => 'e.created_at desc'  });
    $rs->limit( $page_limit );
    $rs->offset( $page_limit * ( $page - 1) );
  }
    
  my $entries = $rs->retrieve;
  my $total   = $self->app->model->search_by_sql('SELECT FOUND_ROWS() AS cnt')->first;
  
  $self->stash('entries', $entries);
  $self->stash('pager'  , { rows => $entries, total => $total->cnt, limit=>$page_limit, current_page=> $page });
  #$self->stash('debug',$rs->as_sql) if( $self->app->mode('development') ); #for debug
  $self->render();
  
}

sub entry {
  my $self = shift;
  my $sitename = $self->param('sitename'); 
  my $timestamp= $self->param('timestamp') || 0;
  
  my $site = $self->app->model->single(
    'sites',
    {
      'basename' => $sitename
    },
  );
  
  my $rs = $self->app->model->resultset(
    {
      select => [q/SQL_CALC_FOUND_ROWS e.*, c.basename as category_basename, s.basename as site_basename/],
    }
  );
  
  {
    $rs->from([]);
    $rs->add_join(
      #select * from entries as e inner join categories as c on e.category_id = c.id ;
      'entries as e' => [
        {
          type  => 'inner',
          table => 'categories as c',
          condition => 'c.id = e.category_id',
        },
      ],
    );
    $rs->add_join(
      'c' => [
        {
          type  => 'inner',
          table => 'sites as s',
          condition => 's.id = c.site_id',
        },
      ],
    );
    $rs->add_where( 'UNIX_TIMESTAMP(e.created_at)' => $timestamp );
  }
  
  if( $site ) {
    $rs->add_where( 'c.site_id' => $site->id );
    $self->stash('site', $site);
    
  }
  
  my $entries = $rs->retrieve;
  my $entry   = $entries->next;
  
  $self->stash('entry', $entry );
  $self->render();
}

1;
