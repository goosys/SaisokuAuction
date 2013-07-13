SaisokuAuction
==============

Mojolicious Application

Installing
------
    cpanm Mojolicious::Plugin::Authentication
    

Config
------
Rename config files and edit them.

    mv conf/admin.conf{.sample,}
    mv conf/affiliateapi.conf{.sample,}
    mv conf/db.conf{.sample,}
    mv conf/website.conf{.sample,}
    mv conf/yahooapi.conf{.sample,}

Setting
------
1. access to /login and login admin page.
2. create sites and categories.


Run
------
    script/cli Create
