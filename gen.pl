#!/usr/bin/env perl
#
# Generates the index page and RSS feed for the site.
#
# Usage:
#
#    ./gen index
#    ./gen feed

use strict;
use warnings;
use POSIX qw(strftime);
use Time::Piece;

my $feed_template = '<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">
  <channel>
    <title>bckly.com</title>
    <description>the blog of logan buckley</description>
    <link>https://bckly.com/</link>
    <atom:link href="https://bckly.com/feed.xml" rel="self" type="application/rss+xml"/>
    <pubDate>NOW</pubDate>
    <lastBuildDate>NOW</lastBuildDate>
    POSTS
  </channel>
</rss>
';

my $item_template = '
      <item>
        <title>TITLE</title>
        <description>DESCRIPTION</description>
        <pubDate>DATE</pubDate>
        <link>LINK</link>
        <guid isPermaLink="true">LINK</guid>
      </item>';

my $index = "<h1>posts</h1\n";
my $feed = $feed_template;
my $feed_posts = "";
my $baseurl = "https://bckly.com";

# Interpolate the current date for the feed.
my $now = strftime("%a, %d %b %Y %H:%M:%S %z", localtime(time()));
$feed =~ s/NOW/$now/g;

sub get_title {
    my ($page) = @_;
    open(my $contents, $page) or die "$page: $!";
    foreach(<$contents>) {
        /^title: (.*)$/ && return $1;
    }
    return undef;
}

sub xml_for_item {
    my ($title, $date, $href, $description) = @_;
    
    # XML-escape the description
    $description =~ s/&/&amp;/g;
    $description =~ s/</&lt;/g;
    $description =~ s/>/&gt;/g;

    my @lt = localtime(Time::Piece->strptime($date, "%Y-%M-%d"));
    $date = strftime("%a, %d %b %Y %H:%M:%S %z", @lt[0..8]); # chokes on the last list elem for some reason
    
    $_ = $item_template;
    s/TITLE/$title/g;
    s/DATE/$date/g;
    s/LINK/${baseurl}${href}/g;
    s/DESCRIPTION/$description/;
    return $_;
}

opendir(my $pages, "posts") or die "Couldn't open dir";
my @pages = readdir($pages);

for (reverse(sort(@pages))) {
    if ($_ =~ /[0-9-]+(.*)\.markdown/) {
        my $title = get_title("posts/$_");
        my ($date) = /^(\d{4}-\d{2}-\d{2})/;
        (my $href = "posts/$_") =~ s/markdown/html/;
        my $description = `pandoc --to html5 posts/$_`;
        $index .= "<div><span class=\"date\">$date</span> <a href=\"/$href\"><h3 class=\"post-listing\">$title</h3></a></div>\n";
        $feed_posts .= xml_for_item($title, $date, $href, $description)
    }
}

$feed =~ s/POSTS/$feed_posts/;
$index .= "<footer><a href=\"about.html\">About</a> | <a href=\"/feed.xml\">Subscribe via RSS</a></footer>";

closedir($pages);

# Output feed or index, depending on the argument passed.
if ($ARGV[0] eq "feed") {
    print $feed;
} elsif ($ARGV[0] eq "index") {
    print $index;
} else {
    print "Usage: ./gen {feed, index}\n";
    exit 1;
}
