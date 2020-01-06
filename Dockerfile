###FROM fmontorsi_builder:1.0 as mytest_builder
###
####RUN apt-get update && \
####    apt-get install -y git build-essential cmake python3-pip && \
####    pip3 install conan
###RUN yum install -y zeromq-devel rsync
###
###RUN gcc --version
###RUN gdb --version
###
###RUN mkdir -p /home/builder /opt/dest
###COPY *.cpp *.h Makefile /home/builder/
###RUN ls -la /home/builder/
###RUN make -C /home/builder/ all
###RUN make -C /home/builder/ install DESTDIR=/opt/mytest
###RUN lddtree -l /opt/mytest/bin/mytest | tee -a /home/builder/dependency_map.txt
####RUN rsync -av -L -K --files-from=/home/builder/dependency_map.txt / /opt/dest/
###RUN tar -c -v -z --absolute-names --files-from=/home/builder/dependency_map.txt -f /opt/dest/output.tar.gz
####ENTRYPOINT [ "/bin/bash" ]
###
####RUN conan install . --build=missing
####RUN conan upload solidity/develop@andreybronin/testing -r andreybronin --all
####RUN conan upload jsoncpp/1.8.4@andreybronin/stable -r andreybronin --all
####RUN conan upload boost/1.70.0@andreybronin/stable -r andreybronin --all

# production Docker container:

FROM scratch
#FROM alpine:latest
COPY bin/ /
#ADD /opt/dest/output.tar.gz /
#RUN ldd /opt/mytest/bin/mytest
EXPOSE 8080
#
#RUN apk update && \
#   apk upgrade && \
#   apk --update add libstdc++ \
#   rm -rf /var/cache/apk/*
#
ENTRYPOINT [ "/opt/mytest/bin/mytest" ]
