package SaisokuAuction::Helper::Widget;

use strict;
use warnings;
use utf8;
use parent qw/Mojolicious::Plugin/;


sub register {
  my ($self,$app) = @_;

  $app->helper( widget_sites             => \&_sites );
  $app->helper( widget_categories        => \&_categories );
  $app->helper( widget_monthly_entries   => \&_monthly_entries );
  
}

sub _sites {
  my ($self, $app) = @_;
  
  my $itr = $self->app->model->search_by_sql(q{
    SELECT 
      s.*, 
      ec.cnt AS cnt 
    FROM 
      sites AS s 
    INNER JOIN (
      SELECT 
        site_id ,count(*) AS cnt 
      FROM 
        categories AS c 
      INNER JOIN 
        entries AS e 
      ON 
        c.id = e.category_id 
      GROUP BY 
        c.site_id
    ) AS ec 
    ON 
      s.id = ec.site_id
    ORDER BY 
      order_number asc
  });
  
  return $itr;
}

sub _categories {
  my ($self, $app) = @_;
  my $site = $self->stash('site');
  
  my $rs = $self->app->model->resultset(
    #select c.* ,count(*) from categories as c inner join entries as e on c.id=e.category_id group by c.id having site_id=8;
    {
      select => [
        q!s.basename as site_basename!, 
        q!categories.*!, 
        q!count(*) as cnt!, 
      ],
    }
  );
  $rs->add_join(
    categories => [
      {
        type  => 'inner',
        table => 'entries as e',
        condition => 'categories.id = e.category_id',
      },
    ],
  );
  $rs->add_join(
    categories => [
      {
        type  => 'inner',
        table => 'sites as s',
        condition => 'categories.site_id = s.id',
      },
    ],
  );
  $rs->group({ column => 'categories.id' });
  $rs->add_having( 'site_id' => $site->id ) if( $site );
  $rs->order({ column => 's.order_number asc' }, { column => 'order_number asc' },{ column => 'id asc' });
  
  return $rs->retrieve; #itr
}

sub _monthly_entries {
  my ($self, $app, $ops) = @_;
  my $category_ids = [];
  
  if( my $site = $self->stash('site') ){
    my $itr = $self->app->model->search('categories',{ 'site_id'=>$site->id } );
    while( my $c = $itr->next ){
      push @$category_ids, $c->id;
    }
  }
  
  my $rs = $self->app->model->resultset(
    {
      select => [
        q!count(*) as cnt!, 
        q!DATE_FORMAT(created_at,'%Y/%m') as created_at_month!
      ],
    }
  );
  $rs->from(['entries']);
  $rs->add_where( 'category_id' => {'IN' => $category_ids} ) if( @$category_ids );
  $rs->group({ column => 'created_at_month' });
  $rs->order({ column => 'created_at_month desc' });
  $rs->limit( $app->{'last_month'} ) if( $app->{'last_month'} );
  
  return $rs->retrieve; #itr
}

1;