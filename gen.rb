#!/usr/bin/env ruby
#
# Generates the homepage and RSS feed for the site.
#
# Usage:
#
#    ./gen index
#    ./gen feed

require 'erb'
require 'time'

$feed_template = <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">
  <channel>
    <title>bckly.com</title>
    <description>the blog of logan buckley</description>
    <link>https://bckly.com/</link>
    <atom:link href="https://bckly.com/feed.xml" rel="self" type="application/rss+xml"/>
    <pubDate><%= Time.now.rfc2822 %></pubDate>
    <lastBuildDate><%= Time.now.rfc2822 %></lastBuildDate>
    <% for @item in @items %>
    <item>
        <title><%= @item.title %></title>
        <description><%= h(@item.description) %></description>
        <pubDate><%= @item.date.strftime("%a, %d %b %Y %H:%M:%S %z") %></pubDate>
        <link><%= @item.link %></link>
        <guid isPermaLink="true"><%= @item.link %></guid>
    </item>
    <% end %>
  </channel>
</rss>
EOF

class Post
  attr_accessor :title, :date, :description, :link

  def initialize(title, date, description, link)
    @title = title
    @date = Date.parse(date)
    @description = description
    @link = link
  end
end

class AtomFeed
  include ERB::Util

  attr_accessor :items

  def initialize(items)
    @items = items
  end

  def render()
    ERB.new($feed_template).result(binding())
  end
end

post = Post.new('my first post', '2017-01-01', 'some <a>stuff here</a>', 'http://example.com/first.html')
posts = [post]

puts AtomFeed.new(posts).render()
