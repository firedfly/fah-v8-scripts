# onstart script for Folding@Home v8 running on vast.ai

  echo "**** install runtime packages ****" && \
  apt-get update && \
  apt-get install -y \
    bzip2 \
    intel-opencl-icd \
    libexpat1 \
    screen \
    pipx && \
  pipx install lufah && \
   mkdir /var/log/fah-client && \
  ln -s libOpenCL.so.1 /usr/lib/x86_64-linux-gnu/libOpenCL.so && \
  echo "**** install foldingathome ****" && \
  download_url="https://download.foldingathome.org/releases/public/fah-client/debian-10-64bit/release/fah-client_8.3.18-64bit-release.tar.bz2" && \
  curl -o \
    /tmp/fah.tar.bz2 -L \
    ${download_url} && \
  tar xf /tmp/fah.tar.bz2 -C /root --strip-components=1 && \
  echo "**** cleanup ****" && \
  apt-get clean && \
  rm -rf \
    /tmp/* \
    /var/lib/apt/lists/* \
    /var/tmp/* \
    /var/log/*

set $FAH_MACHINE_NAME="Vast.ai-$VAST_CONTAINERLABEL"
screen -dm ./fah-client --log=/var/log/fah-client/log.txt --log-rotate-dir=/var/log/fah-client/ --account-token=$FAH_ACCOUNT_TOKEN --machine-name=$FAH_MACHINE_NAME --cpus 0

sleep 10

.local/bin/lufah -a / enable-all-gpus
#.local/bin/lufah -a / fold