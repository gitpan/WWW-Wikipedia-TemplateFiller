#!/usr/bin/perl

# This points to the templates/ directory to be used
my $template_path = '/var/www/hocdev/cgi-bin/templatefiller/templates/';

use WWW::Wikipedia::TemplateFiller::WebApp;
WWW::Wikipedia::TemplateFiller::WebApp->new( TMPL_PATH => $template_path )->run;
