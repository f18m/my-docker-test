#
# Main makefile that
#  - cross compiles an application
#  - creates an optimized Docker to run it
#
# USEFUL APP#1:
#   dockerize (https://github.com/jwilder/dockerize) is able to collect all ELF required
#   dependencies and produce a docker out of them. PROBLEM: requires the ELF to have been
#   built on the baremetal -- we want to build the application inside a docker instead
#   to make sure we can build the application on any OS we like
#
# USEFUL APP#2
#  Dive (https://github.com/wagoodman/dive) can be used to explore each layer of a Docker image
#
# MY NOTE ABOUT MULTI-STAGE DOCKER:
#

VERSION:=1.0


# targets to run on your baremetal:

docker-builder-base:
	@echo "=============================> BUILDING BASE BUILDER IMAGE"
	docker build -t fmontorsi_builder:$(VERSION)  .                  -f Dockerfile.buildbase

docker-2stages: docker-builder-base
	@echo "=============================> BUILDING STAGE1"
	# prepare images for cross-compiling:
	docker build -t mytest:build                  .                  -f Dockerfile.stage1-build
	# extract result of cross-compiling into bin/
	docker rm -f extract || true
	docker create --name extract                  mytest:build
	mkdir -p bin && rm -rf bin/*
	docker cp extract:/opt/dest/output.tar.gz     bin/
	cd bin && tar -xvf output.tar.gz && rm -f output.tar.gz
	docker rm -f extract
	# now build the production container:
	@echo "=============================> BUILDING STAGE2"
	docker build -t mytest:$(VERSION)             .                  -f Dockerfile.stage2-production
	
docker-multistage: docker-builder-base
	# build & produce production docker in a single step:
	@echo "=============================> BUILDING MULTISTAGE DOCKER"
	docker build -t mytest:$(VERSION)             .                  -f Dockerfile.multistage

docker-run:
	docker run -it --rm --name mytest -P mytest:$(VERSION)


# targets that are run from inside Dockers:

all:
	gcc -o mytest mytest.cpp -lzmq

install:
	mkdir -p $(DESTDIR)/bin/
	cp -afv mytest $(DESTDIR)/bin/
