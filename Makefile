POST_SOURCES := $(wildcard posts/*.markdown)
PAGES := site/moby-dick-poems.html site/about.html site/asteroids/index.html
POSTS_HTML := $(POST_SOURCES:posts/%.markdown=site/posts/%.html)
PANDOC_FLAGS := --to html5 --smart --template template.html

site/index.html: $(POSTS_HTML) site/feed.xml site/main.css $(PAGES) gen.pl site/img template.html site/cv.pdf
	./gen.pl index | pandoc $(PANDOC_FLAGS) -o $@
	./alias.pl

site/feed.xml: $(POSTS_HTML) $(PAGES)
	./gen.pl feed > $@

site/cv.pdf:
	cp cv.pdf site/cv.pdf

site/main.css: main.css
	cp main.css site/

site/%.html: pages/%.markdown template.html
	@mkdir -p site
	pandoc $(PANDOC_FLAGS) $< -o $@

site/asteroids/index.html:
	cp -r pages/asteroids site/asteroids

site/img:
	cp -r img site/img

site/posts/%.html: posts/%.markdown template.html
	@mkdir -p site/posts
	pandoc $(PANDOC_FLAGS) $< -o $@

site/drafts/%.html: drafts/%.markdown template.html
	@mkdir -p site/drafts
	pandoc $(PANDOC_FLAGS) $< -o $@

clean:
	rm -rf site/*

serve: site/index.html
	cd site/ && python3 -m http.server
