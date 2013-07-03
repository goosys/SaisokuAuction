package SaisokuAuction::Helper::Pagination;

use strict;
use warnings;
use utf8;
use parent qw/Mojolicious::Plugin/;
use POSIX;

sub register {
  my ($self,$app) = @_;

  $app->helper( pager => \&_pager );
  
}

sub _pager {
  my ($self, $app, $p, $ops ) = @_;
  $p   ||= $self->stash('pager');
  $ops ||= {  };
  ##ex) $p = { rows => $entries, total => $total->cnt, limit=>3, current_page=> $page }
  
  my $ul = [];
  my $page_cnt = ceil($p->{total} / $p->{limit});
  
  foreach my $ii ( 1..$page_cnt ){
    my $li = { page => $ii, };
    $li->{current} = ( $ii == $p->{current_page} );
    
    push @$ul, $li;
  }
  
  return $ul;
}

1;