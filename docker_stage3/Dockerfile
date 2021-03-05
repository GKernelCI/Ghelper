FROM debian:bullseye

ARG stage3_url=nogooddefault
RUN apt-get update && apt-get -y install qemu wget xz-utils qemu-user-static unzip rsync
RUN wget -q $stage3_url
RUN mkdir /gentoo && cd /gentoo && tar xJpf /stage3*xz && rm /stage3*xz
RUN mkdir -p /gentoo/var/db/repos/gentoo/ && echo "PORTDIR=\"$PORTDIR\"" >> /gentoo/etc/portage/make.conf
RUN wget --quiet https://github.com/gentoo/gentoo/archive/master.zip -O /master.zip && unzip -q master.zip && mv /gentoo-master/* /gentoo/var/db/repos/gentoo/ && rm master.zip
# no privacy problem
RUN echo "nameserver 8.8.8.8" > /gentoo/etc/resolv.conf
RUN chmod 644 /gentoo/etc/resolv.conf
# https://bugs.gentoo.org/703276 for -network-sandbox
# https://forums.gentoo.org/viewtopic-t-1092314-start-0.html for -pid-sandbox
RUN echo 'FEATURES="-network-sandbox -pid-sandbox"' >> /gentoo/etc/portage/make.conf

COPY builder.sh /gentoo
COPY builder2.sh /gentoo
COPY builder3.sh /gentoo
COPY prereq.sh /gentoo
COPY prereq2.sh /gentoo
RUN chmod +x /gentoo/builder*
RUN chmod +x /gentoo/prereq*
