#
# Main makefile that
#  - cross compiles an application
#  - creates an optimized Docker to run it
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

VERSION:=1.4
THISDIR:=$(shell readlink -f .)
DEBUG_PORT:=20002

PROD_IMAGE_NAME:=f18m/my-docker-test
PROD_CONTAINER_NAME=mytest


MOUNT_CORE_PATH:=/cores
LOCAL_CORE_PATH:=/tmp/$(PROD_CONTAINER_NAME)_coredumps_volume

MOUNT_LOG_PATH:=/logs
LOCAL_LOG_PATH:=/tmp/$(PROD_CONTAINER_NAME)_log_volume

# targets to run on your baremetal:

docker-builder-base:
	@echo "=============================> BUILDING BASE BUILDER IMAGE"
	docker build -t fmontorsi_builder:1           .                  -f Dockerfile.build-base

docker-prod-base:
	@echo "=============================> BUILDING BASE PROD IMAGE"
	docker build -t fmontorsi_prod:1           .                  -f Dockerfile.prod-base


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
	docker build -t mytest:$(VERSION)             .                  -f Dockerfile.multistage


#
# SOLUTION #3: use the docker builder image mounting a shared volume
# PRO: single Dockerfile, allows for incremental builds
# CON: 
#

docker-sharedvolume: docker-builder-base docker-prod-base
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
	cd output && tar -xvf mytest.tar.gz  
	#&& rm -f mytest.tar.gz
	@echo "=============================> BUILDING STAGE2"
	docker build -t $(PROD_IMAGE_NAME):$(VERSION)             .                  -f Dockerfile.sharedvolume.stage2-production

docker-build-valgrind:
	@echo "=============================> BUILDING VALGRIND"
	docker build -t $(PROD_IMAGE_NAME):$(VERSION).valgrind 		.				 -f Dockerfile.valgrind

#	
# Test produced docker:
#
#to have core dumps you must set the core pattern of your local machine
#to read core dumps locally you have to set sysroot output/ in gdb
set-local-core-path:
	echo "$(MOUNT_CORE_PATH)/core.%e.%p.%t	" >  /proc/sys/kernel/core_pattern

docker-push:
	docker push $(PROD_IMAGE_NAME):$(VERSION)

docker-run:
	docker run --privileged -it --rm  --cap-add sys_ptrace --ulimit core=-1 -v $(LOCAL_CORE_PATH):$(MOUNT_CORE_PATH)  --name $(PROD_CONTAINER_NAME) -P $(PROD_IMAGE_NAME):$(VERSION)

docker-run-daemon:
	docker run --privileged -it -d --rm --cap-add sys_ptrace  --ulimit core=-1 -v $(LOCAL_CORE_PATH):$(MOUNT_CORE_PATH) --name $(PROD_CONTAINER_NAME) -P $(PROD_IMAGE_NAME):$(VERSION)
	
docker-attach:
	docker exec -it --privileged  $(PROD_CONTAINER_NAME) /bin/bash	
	
docker-run-bash:
	docker run --privileged -it --rm --entrypoint /bin/bash --cap-add sys_ptrace --ulimit core=-1 -v $(LOCAL_LOG_PATH):$(MOUNT_LOG_PATH)  -v $(LOCAL_CORE_PATH):$(MOUNT_CORE_PATH)  --name $(PROD_CONTAINER_NAME)-bash -P $(PROD_IMAGE_NAME):$(VERSION)

docker-stop:
	docker stop $(PROD_CONTAINER_NAME)

#run gdb on docker container 
#attach gdb to process 1 (entrypoint)
#CON: you can't see source code
docker-debug:	
	docker exec -it --privileged  $(PROD_CONTAINER_NAME) /usr/bin/gdb.minimal -p 1

#run gdbserver on the docker container
#attach gdbserver to process 1
#run gdb on local machine with target remote
#PRO: You can see source code
docker-debug-remote:
	$(eval CONTAINER_IP_ADDRESS := $(shell docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(PROD_CONTAINER_NAME)))
	docker exec -d --privileged  $(PROD_CONTAINER_NAME) /usr/bin/gdbserver --attach localhost:$(DEBUG_PORT) 1 
	gdb $(THISDIR)/output/project/build/mytest --eval-command="target remote $(CONTAINER_IP_ADDRESS):$(DEBUG_PORT)"
	
#to run valgrind you can use a specific image or modify the entrypoint	(I prefer the second one)
docker-run-valgrind:
#	docker run --rm -ti --name mytest-valgrind -P mytest_valgrind:$(VERSION)
	docker run --rm -ti --entrypoint /usr/bin/valgrind --name $(PROD_CONTAINER_NAME)-valgrind -v $(LOCAL_LOG_PATH):$(MOUNT_LOG_PATH) -P $(PROD_IMAGE_NAME):$(VERSION) --log-file=$(MOUNT_LOG_PATH)/valgrind.log /project/build/mytest

