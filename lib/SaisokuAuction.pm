package SaisokuAuction;
use Mojo::Base 'Mojolicious';

use SaisokuAuction::Model;

# This method will run once at server start
sub startup {
  my $self = shift;

  # Documentation browser under "/perldoc"
  $self->plugin('PODRenderer');
  $self->plugin('SaisokuAuction::Helper::Widget');

  # Load Config
  my $config = $self->plugin(
      'Config',
      { file => $self->app->home->rel_file('conf/affiliateapi.conf') }
  );
  my $config_db = $self->plugin(
      'Config',
      { file => $self->app->home->rel_file('conf/db.conf') }
  );
  my $config_website = $self->plugin(
      'Config',
      { file => $self->app->home->rel_file('conf/website.conf') }
  );
  $self->attr( conf_api => sub { $config } );
  $self->attr( conf_website => sub { $config_website->{Website} } );
  $self->attr( model => sub { SaisokuAuction::Model->new( $config_db->{DB} ) });
  
  #Hook
  {
    $self->app->hook(after_render => sub {
      my ($c, $output, $format) = @_;
      
      if( $format eq 'html' ){
        my $url = $self->conf_api->{affiliurl};
        $$output =~ s|http://\w+\.auctions\.yahoo\.co\.jp/|$url$&|g;
        $$output =~ s|http://auctions\.yahooapis\.jp/AuctionWebService/V2/sellingList\?sellerID=([^\"]+)|${url}http://openuser.auctions.yahoo.co.jp/jp/show/auctions\?userID=$1|g; #"
        $$output =~ s|http://auctions\.yahooapis\.jp/AuctionWebService/V1/ShowRating\?id=([^\"]+)|${url}http://auctions.yahoo.co.jp/jp/show/rating?userID=$1|g; #"
      }
    });
  }
  
  # Formats
  $self->types->type(rdf => 'text/xml; charset=utf-8');
  $self->types->type(xml => 'text/xml; charset=utf-8');
  
  # Router
  my $r = $self->routes;
  {
    my $f = { num => qr/\d+/ };
  
    $r->get('/')->to('site#index');
    
    # 
    $r->route('/sitemap', format=>'xml' )
      ->via('GET')
      ->to( controller => 'feed', action=>'sitemap' );
    
    # 
    $r->route('/:page', page => $f->{num} )
      ->via('GET')
      ->to( controller => 'site', action=>'index', page => 1 );
    
    # 
    $r->route('/:sitename/:timestamp', timestamp => qr/\d{10}/ )
      ->via('GET')
      ->to( controller => 'site', action=>'entry' );
    
    # 
    $r->route('/:sitename/:page', page => $f->{num}, sitename => qr/\D\w+/ )
      ->via('GET')
      ->to( controller => 'site', action=>'index', page => 1 );
      
    # 
    $r->route('/:sitename/archive/:categoryname/:page', page => $f->{num}, categoryname => qr/\D\w+/ )
      ->via('GET')
      ->to( controller => 'site', action=>'index', page => 1, archive => 'category' );
      
    # 
    $r->route('/:sitename/archive/:year/:month/:page',  page => $f->{num}, year => qr/\d{4}/, month => qr/\d{2}/  )
      ->via('GET')
      ->to( controller => 'site', action=>'index', page => 1, archive => 'monthly' );
      
    # 
    $r->route('/archive/:year/:month/:page',  page => $f->{num}, year => qr/\d{4}/, month => qr/\d{2}/  )
      ->via('GET')
      ->to( controller => 'site', action=>'index', page => 1, archive => 'monthly' );
    
    # 
    $r->route('/:sitename/rss', format=>'rdf', sitename => qr/\D\w+/ )
      ->via('GET')
      ->to( controller => 'feed', action=>'rss' );
      
    # 
    $r->route('/:sitename/rss/:categoryname', sitename => qr/\D\w+/, categoryname => qr/\D\w+/ )
      ->via('GET')
      ->to( controller => 'feed', action=>'rss', archive => 'category' );
    
    #
    $r->route('/admin/:controller/:id', id => $f->{num})
      ->via('GET')
      ->to( controller=>'site', action => 'index', id => undef, namespace => 'SaisokuAuction::Admin');
      
    #
    $r->route('/admin/:controller/create/:parent_id', id => $f->{num})
      ->via('GET')
      ->to( controller=>'site', action => 'create', parent_id => undef, namespace => 'SaisokuAuction::Admin');
    
    #
    $r->route('/admin/:controller/:action/:id', id => $f->{num})
      ->via('GET')
      ->to( controller=>'site', action => 'index', id => undef, namespace => 'SaisokuAuction::Admin');
    
    #
    $r->route('/admin/:controller/create')
      ->via('POST')
      ->to( action => 'create', namespace => 'SaisokuAuction::Admin');
    
    
  }
}

1;
