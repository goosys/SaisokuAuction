package SaisokuAuction::Feed;
use Mojo::Base 'Mojolicious::Controller';

sub rss {
  my $self = shift;
  my $sitename = $self->param('sitename');
  my $archive  = $self->param('archive') || 0;
  my $page_limit = 50; 
  
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
    $rs->order({ 'column' => 'e.created_at desc'  });
    $rs->limit( $page_limit );
  }
  
  my $latest  = $rs->retrieve;
  my $entries = $rs->retrieve;
  my $website = $self->app->conf_website;
  
  $self->stash('latest',  $latest->next  );
  $self->stash('entries', $entries);
  $self->stash('website', $website);
  $self->stash('format', 'rdf'); 
  $self->render();
  
}

sub sitemap {
  my $self = shift;
  
  my $latest = $self->app->model->search_by_sql(q{
    SELECT * FROM entries ORDER BY created_at desc limit 1
  });
  
  #select l.id, s.basename as site_basename, l.site_id, l.basename as category_basename, l.last_update_at from (select id, site_id, basename, (select created_at from entries as e where e.category_id = c.id order by created_at desc limit 1) as last_update_at from categories as c order by site_id asc) as l inner join sites as s on s.id = l.site_id where last_update_at is not null;
  my $categories = $self->app->model->search_by_sql(q{
    SELECT 
      l.id, 
      s.basename AS site_basename, 
      l.site_id, 
      l.basename AS category_basename, 
      l.last_update_at 
    FROM (
      SELECT 
        id, site_id, basename, (
          SELECT 
            created_at 
          FROM 
            entries as e 
          WHERE 
            e.category_id = c.id 
          ORDER BY 
            created_at desc 
          LIMIT 1
        ) AS last_update_at 
      FROM 
        categories as c 
      ORDER BY
        site_id asc
    ) AS l 
    INNER JOIN 
      sites AS s 
    ON 
      s.id = l.site_id
    WHERE 
      last_update_at IS NOT NULL
  });
  
  #select s.id, s.basename, max(e.created_at) as last_update_at from sites as s inner join categories as c on s.id = c.site_id inner join entries as e on e.category_id = c.id group by s.id;
  my $sites = $self->app->model->search_by_sql(q{
    select 
      s.id, 
      s.basename, 
      max(e.created_at) as last_update_at 
    from 
      sites as s 
    inner join 
      categories as c 
    on 
      s.id = c.site_id 
    inner join 
      entries as e 
    on 
      e.category_id = c.id 
    group by 
      s.id
  });
  
  $self->stash('latest', $latest->next ); 
  $self->stash('sites', $sites  ); 
  $self->stash('categories', $categories ); 
  $self->stash('format', 'xml'); 
  $self->render();
  
}

1;
