# onstart script for Folding@Home v8 running on vast.ai

  echo '**** ensuring we are in the /root  directory ****'
  cd /root

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
  echo "**** install foldingathome ****" && \
  download_url="https://download.foldingathome.org/releases/public/fah-client/debian-10-64bit/release/fah-client_8.4.9-64bit-release.tar.bz2" && \
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
    echo "FAH username specified; Updating machine name"
    FAH_MACHINE_NAME=$FAH_MACHINE_NAME-$FAH_USERNAME
fi

# make the current environment variables available to a standard shell 
env >> /etc/environment;

echo "Starting fah-clinent"
screen -dm ./fah-client --log=/var/log/fah-client/log.txt --log-rotate-dir=/var/log/fah-client/ --account-token=$FAH_ACCOUNT_TOKEN --machine-name=$FAH_MACHINE_NAME --cpus 0

echo "Waiting 10 seconds for fah-client to start..."
sleep 10

echo "Enabling all GPUs"
.local/bin/lufah -a / enable-all-gpus

echo "===================================="
echo "Beginning FAH configuration loop"
while :
do
    if [[ -v FAH_USERNAME ]]; then
        FAH_CURRENT_USERNAME=$(.local/bin/lufah -a / config user)
        if [[ $FAH_CURRENT_USERNAME != "\"$FAH_USERNAME\"" ]]
        then
            echo "FAH username specified.  Updating FAH config"
            .local/bin/lufah -a / config user $FAH_USERNAME
            echo "---"
        fi
    fi

    if [[ -v FAH_TEAM ]]; then
        FAH_CURRENT_TEAM=$(.local/bin/lufah -a / config team)
        if [[ $FAH_CURRENT_TEAM != "$FAH_TEAM" ]]
        then
            echo "FAH team specified.  Updating FAH config"
            .local/bin/lufah -a / config team $FAH_TEAM
            echo "---"
        fi
    fi

    if [[ -v FAH_PASSKEY ]]; then
        FAH_CURRENT_PASSKEY=$(.local/bin/lufah -a / config passkey)
        if [[ $FAH_CURRENT_PASSKEY != "\"$FAH_PASSKEY\"" ]]
        then
            echo "FAH passkey specified.  Updating FAH config"
            .local/bin/lufah -a / config passkey $FAH_PASSKEY
            echo "---"
        fi
    fi


    if [[ -v FAH_AUTOSTART && $FAH_AUTOSTART = "true" ]]; then
        echo "FAH autostart enabled."

        FAH_CURRENT_USERNAME=$(.local/bin/lufah -a / config user)
        if [[ -v FAH_USERNAME && $FAH_CURRENT_USERNAME != "\"$FAH_USERNAME\"" ]]
        then
            echo "Configured user ($FAH_CURRENT_USERNAME) does not match the specified user.  Will retry configuration"
            echo "---"
            echo "---"
            sleep 1
            continue;
        fi
        
        FAH_CURRENT_TEAM=$(.local/bin/lufah -a / config team)
        if [[ -v FAH_TEAM && $FAH_CURRENT_TEAM != "$FAH_TEAM" ]]
        then
            echo "Configured team ($FAH_CURRENT_TEAM) does not match the specified team.  Will retry configuration"
            echo "---"
            echo "---"
            sleep 1
            continue;
        fi
        
        FAH_CURRENT_PASSKEY=$(.local/bin/lufah -a / config passkey)
        if [[ -v FAH_PASSKEY && $FAH_CURRENT_PASSKEY != "\"$FAH_PASSKEY\"" ]]
        then
            echo "Configured passkey ($FAH_CURRENT_PASSKEY) does not match the specified passkey.  Will retry configuration"
            echo "---"
            echo "---"
            sleep 1
            continue;
        fi

        echo "Configuration finished.  Folding starting"
        .local/bin/lufah -a / fold

        # we only want to start folding once.  after one time, we enter the loop to ensure
        # the configuration is still accurate (not overridden by account settings)
        FAH_AUTOSTART=false
    fi

    # Sleep 5 seconds and then double check the config is accuate still
    sleep 5
done