usage:
	@echo "usage: make TARGET"
	@echo
	@echo "targets:"
	@echo "  test"
	@echo "  travis [FILE=<...>]"

# Parallel testing
test:
	carton exec "prove -l -j 4 -r t"

# Travis like test/cover
travis:
	carton exec 'cpanm --notest Perl::Tidy'
	carton exec 'cpanm --quiet --notest --skip-satisfied Devel::Cover'
	carton exec 'perl Build.PL && ./Build build'
	if [ -d cover_db ]; then rm -rf cover_db/ ; fi
ifeq ($(strip $(FILE)),)
	carton exec 'cover -test'
else
	carton exec "PERL5OPT=-MDevel::Cover env perl -Ilib ${FILE}"
endif
	if [ -d cover_db ]; then rm -rf cover_db/ ; fi
	carton exec './Build realclean'
