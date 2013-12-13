
all: paper

paper: *.tex *.bib *.cls
	pdflatex paper.tex
	bibtex paper
	pdflatex paper.tex
	pdflatex paper.tex
	cp paper.pdf ~/public_html/comp116/

clean:
	rm -f *.aux *.bbl *.blg *.log

