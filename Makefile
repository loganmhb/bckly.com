POST_SOURCES := $(wildcard posts/*.markdown)
PAGES := site/moby-dick-poems.html site/about.html site/asteroids/index.html
POSTS_HTML := $(POST_SOURCES:posts/%.markdown=site/posts/%.html)
PANDOC_FLAGS := --to html5 --smart --template template.html

# TODO:
# - Convert Jekyll templates to Pandoc
# - Figure out what to do about non-post pages
# - Generate an index page
# - Generate RSS/atom feed

site/index.html: $(POSTS_HTML) site/main.css $(PAGES) gen_index.pl
	echo $(PAGES)
	echo $(PANDOC_FLAGS)
	./gen_index.pl | pandoc $(PANDOC_FLAGS) -o $@

site/main.css: main.css
	cp main.css site/

site/%.html: pages/%.markdown
	pandoc $(PANDOC_FLAGS) $< -o $@

site/asteroids/index.html:
	cp -r pages/asteroids site/asteroids

site/posts/%.html: posts/%.markdown main.css
	pandoc $(PANDOC_FLAGS) $< -o $@

clean:
	rm -rf site/*.html

serve: site/index.html
	cd site/ && python -m http.server
