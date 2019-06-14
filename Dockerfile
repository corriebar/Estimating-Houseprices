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

RUN installGithub.r ropenscilabs/icon \
		gadenbuie/xaringanthemer \
	&& rm -rf /tmp/downloaded_packages/

#RUN R -e "devtools::install_github('ropenscilabs/icon')" \
#	&& R -e "devtools::install_github('gadenbuie/xaringanthemer')"
