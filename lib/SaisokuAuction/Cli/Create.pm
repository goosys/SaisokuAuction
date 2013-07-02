use strict;
use warnings;
use utf8;

package SaisokuAuction::Cli::Create;
use Mojo::Base ('SaisokuAuction::Cli','Mojolicious::Renderer');

use Mail::IMAPClient;
use LWP::Simple qw(get);
use XML::Simple;

sub run {
  my $self = shift;
  local @ARGV = @_; 

  $self->setup;
  
  my $mail_rows = $self->model->search('categories');
  my $mails = [];
  while( my $mail = $mail_rows->next ){
    push @$mails, $mail;
  }
  
  my $got_mails = $self->_get_mails( $mails );
  my $aids      = $self->_get_urls( $got_mails->{lines} );
  my $products  = $self->_get_products( $aids );
  $self->_create_entries( $got_mails->{id}, $products );
  
}

sub _get_mails {
  my $self  = shift;
  my $mails = shift;
  
  say 'start: IMAP';
  
  my $conf_mail = $self->conf_api->{mail};
  say $conf_mail->{Server};

  my $folder = 'INBOX.alert';
  my $imap = Mail::IMAPClient->new( %{$conf_mail} );
  $imap->connect() or die;
  $imap->login();
  $imap->select( "inbox" );
  $imap->Uid(1);
  foreach ( 1..@$mails ){ my $dm = splice(@$mails,int(rand(@$mails)),1); push @$mails,$dm; } #shuffle

  my $mail_id;
  my $lines =[];
  foreach my $mail ( @$mails ){
    my $title = $mail->alert_subject;
    $mail_id  = $mail->id;

    Encode::_utf8_on($title);
    my $alert= join('', $self->conf_api->{format_str}{before}, $title, $self->conf_api->{format_str}{after});
    $alert = Encode::encode('utf-8',$alert);
    say 'keyword :'. $alert; 

    my @uids = $imap->search('CHARSET','UTF-8','UNSEEN','SUBJECT',$alert);
    #say join(',',@uids);
    
    foreach my $uid( @uids) {
      push @$lines , [split(/\n/,$imap->body_string($uid))];

      my $subject = $imap->subject($uid);
      $imap->delete_message($uid);
      $imap->expunge;
      say Encode::encode('utf-8',Encode::decode('MIME-Header',$subject));

      last if( @$lines > 9 );

    }
    last if (@$lines) ;
  }
  
  $imap->close();
  $imap->logout();
  
  say 'finish: IMAP';
  
  return { id=> $mail_id, lines => $lines };
}

sub _get_urls {
  my $self  = shift;
  my $lines = shift;

  my $aids = [];
  map { map{ if( m|http://[^\.]+\.auctions\.yahoo\.co\.jp/jp/auction/([a-z]?[0-9]+)| ) { push @$aids,$1 } } @$_} @$lines;
  map { say $_ } @$aids;
  
  return $aids;
}

sub _get_products {
  my $self  = shift;
  my $aids  = shift;
  
  my $conf_api = $self->conf_api->{appid};
  my $YahooAPIID = $conf_api;
  
  $XML::Simple::PREFERRED_PARSER = 'XML::Parser';
  my $xmlparser = XML::Simple->new();
  
  my $products =[];
  
  foreach my $aid ( @$aids ){
    my $tree = get( "http://auctions.yahooapis.jp/AuctionWebService/V2/auctionItem?appid=" . $YahooAPIID. "&auctionID=". $aid );
    
    my $results   = $xmlparser->XMLin($tree);
    if( $results->{Error}->{Message} ){
      
    }else{
      if( my $result = $results->{Result} ){
        push @$products, $result;
        #say $result->{Title};
      }
    }
    #last; #for debug
  }
  
  return $products;
}

sub _create_entries {
  my $self     = shift;
  my $mail_id  = shift;
  my $products = shift;
  
  use Mojolicious::Controller;
  my $ctrl = Mojolicious::Controller->new;
  $self->app->plugin('EPRenderer');
  $ctrl->app->renderer->paths->[0] = $self->rel_dir('templates');
  say $self->rel_dir('templates');
  
  my $title = $products->[0]{Title};
  my $body  = '';
  foreach my $p ( @$products ){
  
    $body  .= $ctrl->render(
      template => 'formats/article',
      partial => 1, 
      p => $p
    ) ||'';
  
  }
  
  $self->model->create(
    'entries',
    {
      category_id  => $mail_id,
      title        => $title,
      body         => $body,
    }
  );
  
  return;
}

1;