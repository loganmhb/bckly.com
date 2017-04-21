#!/usr/bin/env perl
#
# Generate aliases like Hugo:
#  https://gohugo.io/extras/aliases/
use strict;
use warnings;
use File::Basename qw(fileparse);
use File::Path qw(make_path);

my $alias_template = "<!DOCTYPE html>
<html>
  <head>
    <title>HREF</title>
    <link rel=\"canonical\" href=\"HREF\"/>
    <meta http-equiv=\"content-type\" content=\"text/html; charset=utf-8\"/>
    <meta http-equiv=\"refresh\" content=\"0; url=HREF\"/>
  </head>
</html>";

open my $aliasfile, '<', 'aliases';

for(<$aliasfile>) {
    /^(.*) -> (.*)$/;
    my $old = $1;
    my $new  = $2;

    # Format the template with the new canonical link.
    my $contents = $alias_template;
    $contents =~ s/HREF/https:\/\/bckly.com$new/g;

    # Generate the alias file and any needed directories.
    my ($file, $dir) = fileparse($old);
    make_path("site$dir");
    open my $out, '>', "site$dir$file" or die "$!: $dir$file";
    print $out $contents;
}
