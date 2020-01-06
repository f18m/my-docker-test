VERSION:=1.0

all:
	gcc -o mytest mytest.cpp -lzmq

install:
	mkdir -p $(DESTDIR)/bin/
	cp -afv mytest $(DESTDIR)/bin/

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
	####dockerize -t mytest:1.0 $(PWD)/mytest
	# use https://github.com/wagoodman/dive to explore each layer

docker-run:
	docker run -it --rm --name mytest -P mytest:$(VERSION)
