#!/usr/bin/perl

#use lib '/home/diberri/lib';
use WWW::Wikipedia::TemplateFiller::WebApp;
WWW::Wikipedia::TemplateFiller::WebApp->new( TMPL_PATH => '/var/www/hocdev/cgi-bin/templatefiller/templates/' )->run;
