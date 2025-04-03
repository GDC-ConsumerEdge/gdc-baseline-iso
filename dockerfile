FROM ubuntu:20.04
RUN apt-get update -y && apt-get install -y wget whois diceware p7zip-full fdisk xorriso
COPY . /opt/edge-ubuntu-20-04-autoinstall
WORKDIR /opt/edge-ubuntu-20-04-autoinstall