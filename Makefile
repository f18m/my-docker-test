# targets that are run from inside Dockers:

THISDIR:=$(shell readlink -f .)

<<<<<<< HEAD
all:
	mkdir -p build && rm -rf build/*
	gcc -c -o build/mytest.o mytest.cpp
	gcc -o build/mytest build/mytest.o -lzmq

install: all
	# typical installation procedure may look like:
	#    mkdir -p $(DESTDIR)/bin/
	#    cp -afv mytest $(DESTDIR)/bin/
	# instead to meet Docker logic of shipping all binaries and dependencies, we
	# package the app binary and all its companion shared libraries:
	mkdir -p $(DESTDIR)
	lddtree -l $(THISDIR)/build/mytest | tee -a /tmp/dependency_map.txt
	tar --dereference -c -v -z --absolute-names --files-from=/tmp/dependency_map.txt -f $(DESTDIR)/mytest.tar.gz
=======
# targets to run on your baremetal:

docker-builder-base:
	@echo "=============================> BUILDING BASE BUILDER IMAGE"
	docker build -t fmontorsi_builder:1           .                  -f Dockerfile.build-base


#
# SOLUTION #1: 2 different stages, using 2 Dockerfiles
# PRO: simple to understand, provides output on host filesystem
# CON: does not easily allow to do incremental builds, lots of commands, hard to maintain perhaps
#
#  NOTE: this solution is so problematic that I disabled it, use either #2 or #3
#
docker-2stages: docker-builder-base
#	@echo "=============================> BUILDING STAGE1"
#	# prepare images for cross-compiling:
#	docker build -t mytest:build                  .                  -f Dockerfile.stage1-build
#	# extract result of cross-compiling into bin/
#	docker rm -f extract || true
#	docker create --name extract                  mytest:build
#	mkdir -p bin && rm -rf bin/*
#	docker cp extract:/opt/dest/output.tar.gz     bin/
#	cd bin && tar -xvf output.tar.gz && rm -f output.tar.gz
#	docker rm -f extract
#	# now build the production container:
#	@echo "=============================> BUILDING STAGE2"
#	docker build -t mytest:$(VERSION)             .                  -f Dockerfile.stage2-production
	
#
# SOLUTION #2: 2 different stages using a single multistage Dockerfile
# PRO: simple to understand, single Dockerfile
# CON: does not easily allow to do incremental builds
#
docker-multistage: docker-builder-base
	# build & produce production docker in a single step:
	@echo "=============================> BUILDING MULTISTAGE DOCKER"
	docker build -t f18m/my-docker-test:$(VERSION)             .                  -f Dockerfile.multistage


#
# SOLUTION #3: use the docker builder image mounting a shared volume
# PRO: single Dockerfile, allows for incremental builds
# CON: 
#
docker-sharedvolume: docker-builder-base
	@echo "=============================> BUILDING SHARED-VOLUME BUILDER DOCKER"
	docker build -t mytest:build                  .                  -f Dockerfile.sharedvolume.stage1-build
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
	docker build -t f18m/my-docker-test:$(VERSION)             .                  -f Dockerfile.sharedvolume.stage2-production



#
# Test produced docker:
#

docker-push:
	docker push f18m/my-docker-test:$(VERSION)

docker-run:
	docker run -it --rm --name mytest -P f18m/my-docker-test:$(VERSION)

docker-run-daemon:
	docker run -it -d --rm --name mytest -P f18m/my-docker-test:$(VERSION)
>>>>>>> 38cd506f71091fff83c7969ddb7950feb8126d2e
