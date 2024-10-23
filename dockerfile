FROM ubuntu:20.04
RUN apt-get update -y && apt-get install -y xorriso wget p7zip-full isolinux
COPY . /opt/edge-ubuntu-20-04-autoinstall
ENV buildingindocker=true
WORKDIR /opt/edge-ubuntu-20-04-autoinstall