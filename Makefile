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

VERSION:=1.1
THISDIR:=$(shell readlink -f .)

# targets to run on your baremetal:

docker-builder-base:
	@echo "=============================> BUILDING BASE BUILDER IMAGE"
	docker build -t fmontorsi_builder:1           .                  -f Dockerfile.buildbase


#
# SOLUTION #1: 2 different stages, using 2 Dockerfiles
# PRO: simple to understand, provides output on host filesystem
# CON: does not easily allow to do incremental builds, lots of commands, hard to maintain perhaps
#
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
	
#
# SOLUTION #2: 2 different stages using a single multistage Dockerfile
# PRO: simple to understand, single Dockerfile
# CON: does not easily allow to do incremental builds
#
docker-multistage: docker-builder-base
	# build & produce production docker in a single step:
	@echo "=============================> BUILDING MULTISTAGE DOCKER"
	docker build -t mytest:$(VERSION)             .                  -f Dockerfile.multistage


#
# SOLUTION #3: use the docker builder image mounting a shared volume
# PRO: single Dockerfile, allows for incremental builds
# CON: 
#
docker-sharedvolume: docker-builder-base
	@echo "=============================> BUILDING SHARED-VOLUME BUILDER DOCKER"
	docker build -t mytest:build                  .                  -f Dockerfile.sharedvolume
	@echo "=============================> RUNNING SHARED-VOLUME BUILDER DOCKER"
	docker rm -f mybuilder || true
	rm -rf bin/* output/*
	docker run \
		--name mybuilder \
		--env MAKEFILE_OPTS="-C /project -f Makefile.buildapp install DESTDIR=/project/output" \
		--volume $(THISDIR):/project \
		mytest:build
	@echo "=============================> THE BINARY AND ITS DEPENDENCIES ARE NOW AVAILABLE IN $(THISDIR)"
	cd output && tar -xvf mytest.tar.gz && rm -f mytest.tar.gz
	@echo "=============================> BUILDING STAGE2"
	docker build -t mytest:$(VERSION)             .                  -f Dockerfile.stage2-production



#
# Test produced docker:
#

docker-run:
	docker run -it --rm --name mytest -P mytest:$(VERSION)

