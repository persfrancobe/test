#!/usr/bin/perl -I../lib

use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
# use tools; # home-made package for tools
  print $cgi->header(-expires=>'-1d',-charset => 'utf-8');

# see();
exit;