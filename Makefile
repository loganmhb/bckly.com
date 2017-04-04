# FIXME: support nested directories?
SOURCES := $(wildcard src/*.markdown)
PAGES := $(SOURCES:src/%.markdown=site/%.html)

site/index.html: $(PAGES)
	@echo $(SOURCES)
	@echo $(PAGES)
	@echo $(wildcard src/*.markdown)
	@echo "Generating index.html"

site/%.html: src/%.markdown
	pandoc --smart --standalone $< -o $@

clean:
	rm -rf site/*
