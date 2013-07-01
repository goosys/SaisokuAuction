package SaisokuAuction::Model::Schema;
use strict;
use warnings;
use utf8;

use DBIx::Skinny::Schema;
use DateTime;
use DateTime::Format::Strptime;
use DateTime::Format::MySQL;
use DateTime::TimeZone;


my $timezone = DateTime::TimeZone->new(name => 'Asia/Tokyo');
install_inflate_rule '^.+_at$' => callback {
    inflate {
        my $value = shift;
        my $dt = DateTime::Format::Strptime->new(
            pattern   => '%Y-%m-%d %H:%M:%S',
            time_zone => $timezone,
        )->parse_datetime($value);
        return DateTime->from_object( object => $dt );
    };
    deflate {
        my $value = shift;
        return DateTime::Format::MySQL->format_datetime($value);
    };
};

install_utf8_columns qw/title body/;

install_table 'entries' => schema {
    pk 'id';
    columns qw/id category_id basename title body created_at updated_at/;
};

install_table 'categories' => schema {
    pk 'id';
    columns qw/id site_id basename title order_number created_at updated_at/;
};

install_table 'sites' => schema {
    pk 'id';
    columns qw/id basename title order_number created_at updated_at/;
};

1;

__DATA__;
DROP TABLE if EXISTS `entries`;
CREATE TABLE `entries` (
       `id` int(11) unsigned auto_increment NOT NULL,
       `category_id` int(11),
       `basename` tinytext,
       `title` tinytext,
       `body`  text,
       `created_at` timestamp NOT NULL,
       `updated_at` timestamp NOT NULL,
       PRIMARY KEY (`id`)
);
DROP TABLE if EXISTS `categories`;
CREATE TABLE `categories` (
       `id` int(11) unsigned auto_increment NOT NULL,
       `site_id` int(11),
       `basename` tinytext,
       `title` tinytext,
       `order_number` int(11),
       `created_at` timestamp NOT NULL,
       `updated_at` timestamp NOT NULL,
       PRIMARY KEY (`id`)
);
DROP TABLE if EXISTS `sites`;
CREATE TABLE `sites` (
       `id` int(11) unsigned auto_increment NOT NULL,
       `basename` tinytext NOT NULL,
       `title` tinytext,
       `order_number` int(11),
       `created_at` timestamp NOT NULL,
       `updated_at` timestamp NOT NULL,
       PRIMARY KEY (`id`)
);