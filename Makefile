DIRS=TCB NTCB

INCLUDES=$(patsubst %,-I %, $(DIRS))

COQLIBS:=-I ~/devel/cases/src -R ~/devel/cases/theories Case_Tactics

COQC=coqc -q $(INCLUDES) $(COQLIBS)
COQDEP=coqdep $(INCLUDES) $(COQLIBS)
COQDOC=coqdoc
COQEXEC=coqtop $(INCLUDES) -batch -load-vernac-source


OCAMLBUILD=ocamlbuild
OCB_OPTIONS=\
  -j 2 \
  -no-hygiene \
  -no-links \
  -I extraction $(INCLUDES)

VPATH=$(DIRS)
GPATH=$(DIRS)

NTCB=NSet.v Lib.v BinaryAux.v SemanticsProp.v Validator.v DoOption.v
TCB=BinaryDefs.v BinaryProps.v Semantics.v LazyList.v

EXTRACTION=extraction.v

FILES=$(NTCB) $(TCB)

proof: $(FILES:.v=.vo)


extraction: extraction.v
	rm -f extraction/*.ml extraction/*.mli extraction/*.vo
	$(COQEXEC) extraction/extraction.v

#.PHONY: extraction

.SUFFIXES: .v .vo

.v.vo:
#	@rm -f doc/glob/$(*F).glob
	@echo "COQC $*.v"
	@$(COQC) -dump-glob /dev/null $*.v

depend: $(FILES)
	$(COQDEP) $^ \
        > .depend


clean:
	rm -f $(patsubst %, %/*.vo, $(DIRS))
	rm -rf _build
	rm -f doc/coq2html.ml doc/coq2html
	rm -f extraction/*.ml extraction/*.mli



include .depend

FORCE: