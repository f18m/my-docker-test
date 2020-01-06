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

VERSION:=1.0


# targets to run on your baremetal:

docker:
	# prepare images for cross-compiling:
	docker build -t fmontorsi_builder:$(VERSION)  .                 -f Dockerfile.buildbase
	docker build -t mytest:build                  .                 -f Dockerfile.build
	# extract result of cross-compiling into bin/
	docker rm -f extract || true
	docker create --name extract                  mytest:build
	mkdir -p bin && rm -rf bin/*
	docker cp extract:/opt/dest/output.tar.gz     bin/
	cd bin && tar -xvf output.tar.gz && rm -f output.tar.gz
	docker rm -f extract
	# now build the production container:
	docker build -t mytest:$(VERSION)             .                  -f Dockerfile

docker-run:
	docker run -it --rm --name mytest -P mytest:$(VERSION)


# targets that are run from inside Dockers:

all:
	gcc -o mytest mytest.cpp -lzmq

install:
	mkdir -p $(DESTDIR)/bin/
	cp -afv mytest $(DESTDIR)/bin/
