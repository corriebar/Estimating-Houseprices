FROM jackinovik/docker-stan:v0.2.0

RUN apt-get update \
        && apt-get install -y --no-install-recommends \
                libgdal-dev \
                libgeos-dev


RUN install2.r --error \
	xaringan \
	rgeos \
	rgdal \
	maptools \
	mapproj \
	tidybayes \
	cowplot \
	devtools

RUN R -e "devtools::install_github('ropenscilabs/icon')"
