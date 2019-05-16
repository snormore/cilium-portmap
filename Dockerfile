FROM ubuntu:bionic

ADD cilium-portmap.conflist /opt/cilium-portmap.conflist
ADD entrypoint.sh /opt/entrypoint.sh

CMD [ "/opt/entrypoint.sh" ]