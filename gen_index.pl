#!/usr/bin/env perl

opendir(my $pages, "posts") or die "Couldn't open dir";

sub get_title {
    my ($page) = @_;
    open(my $contents, $page) or die "$page: $!";
    foreach(<$contents>) {
        /^title: (.*)$/ && return $1;
    }
    return undef;
}

print "<h1>Contents</h1>\n";
my @pages = readdir($pages);
for (reverse(sort(@pages))) {
    if ($_ =~ /[0-9-]+(.*)\.markdown/) {
        my $title = get_title("posts/$_");
        my ($date) = /^(\d{4}-\d{2}-\d{2})/;
        (my $href = "posts/$_") =~ s/markdown/html/;
        print("<div><span class=\"date\">$date</span> <a href=\"/$href\"><h3>$title</h3></a></div>\n");
    }
}

closedir($pages);
