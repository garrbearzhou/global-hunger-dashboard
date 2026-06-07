FROM rocker/shiny-verse:4.4.2

# Prebuilt CRAN binaries for Ubuntu 24.04 (noble) — no source compile for sf/leaflet stack
ENV RSPM=https://packagemanager.posit.co/cran/__linux__/noble/latest
ENV CRAN=${RSPM}

COPY deploy/install_packages.R /tmp/install_packages.R
RUN Rscript /tmp/install_packages.R

WORKDIR /srv/shiny-server/app
COPY . .

ENV OMP_NUM_THREADS=1
ENV PORT=3838
ENV HOST=0.0.0.0

EXPOSE 3838

CMD ["Rscript", "run_production.R"]
