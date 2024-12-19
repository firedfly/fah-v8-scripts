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

FAH_MACHINE_NAME="Vast.ai-$VAST_CONTAINERLABEL"
if [[ -v FAH_USERNAME ]]; then
    echo "FAH username specified; Adding to machine name"
    FAH_MACHINE_NAME=$FAH_MACHINE_NAME-$FAH_USERNAME
fi

echo "Starting fah-clinent"
screen -dm ./fah-client --log=/var/log/fah-client/log.txt --log-rotate-dir=/var/log/fah-client/ --account-token=$FAH_ACCOUNT_TOKEN --machine-name=$FAH_MACHINE_NAME --cpus 0

echo "Waiting 10 seconds for fah-client to start..."
sleep 10

echo "Enabling all GPUs"
.local/bin/lufah -a / enable-all-gpus

if [[ -v FAH_USERNAME ]]; then
    echo "FAH username specified.  Updating FAH config"
    .local/bin/lufah -a / config user $FAH_USERNAME    
fi

if [[ -v FAH_TEAM ]]; then
    echo "FAH team specified.  Updating FAH config"
    .local/bin/lufah -a / config team $FAH_TEAM
fi

if [[ -v FAH_PASSKEY ]]; then
    echo "FAH passkey specified.  Updating FAH config"
    .local/bin/lufah -a / config passkey $FAH_PASSKEY    
fi

if [[ -v FAH_AUTOSTART && $FAH_AUTOSTART = "true" ]]; then
    echo "FAH autostart enabled.  Folding is starting."
    .local/bin/lufah -a / fold
else
    echo "FAH autostart disabled.  You will need to manually start folding on this machine"
fi
