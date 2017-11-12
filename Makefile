EMACS=emacs
EMACS23=emacs23
EMACS-OPTIONS=

ELS  = flx.el
ELS += flx-ido.el
TEST_ELCS = $(wildcard tests/*.elc)

ELCS = $(ELS:.el=.elc)

.PHONY: test test-nw travis-ci show-version before-test clean

all: $(ELCS)

clean:
	$(RM) $(ELCS) $(TEST_ELCS)

show-version:
	echo "*** Emacs version ***"
	echo "EMACS = `which ${EMACS}`"
	${EMACS} --version

install-ert:
	emacs --batch -L "${PWD}/lib/ert/lisp/emacs-lisp" --eval "(require 'ert)" || ( git clone git://github.com/ohler/ert.git lib/ert && cd lib/ert && git checkout 00aef6e43 )



test:
	$(EMACS) -Q -batch -L . -l tests/flx-test.el -f ert-run-tests-batch-and-exit


travis-ci: before-test
	echo ${EMACS-OPTIONS}
	${EMACS} -batch -Q -l tests/run-test.el

%.elc: %.el
	${EMACS} -batch -Q -L . -f batch-byte-compile $<
