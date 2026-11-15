# Run from the repository root via: make -C research/spoi <target>
ROOT := ../..
PYTHON ?= python
URL ?= https://tungufoss.github.io/maps/research/spoi/site.html

.PHONY: qr poster
qr: $(ROOT)/img/qr/spoi.png

$(ROOT)/img/qr/spoi.png: $(ROOT)/scripts/build_spoi_qr.py $(ROOT)/img/hi/hi_logo.svg
	cd $(ROOT) && $(PYTHON) scripts/build_spoi_qr.py "$(URL)" img/qr/spoi.png

poster: $(ROOT)/img/qr/spoi.png
	cd $(ROOT) && Rscript research/spoi/poster.R
