20a.txt: 20.txt ./blah.pl
	perl ./blah.pl < $< > $@
20b.txt: 20a.txt ../bin/git-vgraph
	../bin/git-vgraph --parents --stdin --test --narrow --no-messages < $< > $@
21b.txt: 21a.txt ../bin/git-vgraph
	../bin/git-vgraph --parents --stdin --test --narrow --no-messages < $< > $@
