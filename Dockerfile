FROM rocker/shiny-verse:4.4.2

RUN apt-get update && apt-get install -y --no-install-recommends \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    && rm -rf /var/lib/apt/lists/*

COPY deploy/install_packages.R /tmp/install_packages.R
RUN Rscript /tmp/install_packages.R

WORKDIR /srv/shiny-server/app
COPY . .

ENV OMP_NUM_THREADS=1
ENV PORT=3838
ENV HOST=0.0.0.0

EXPOSE 3838

CMD ["Rscript", "run_production.R"]
