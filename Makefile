install:
	@unlink /bin/journ &> /dev/null || rm /bin/journ &> /dev/null || true
	ln -s $(CURDIR)/journ.sh /usr/bin/journ
