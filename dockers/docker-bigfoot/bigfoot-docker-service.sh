#!/bin/bash

function getMountPoint()
{
    echo $1 | python -c "import sys, json, os; mnts = [x for x in json.load(sys.stdin)[0]['Mounts'] if x['Destination'] == '/usr/share/sonic/hwsku']; print '' if len(mnts) == 0 else os.path.basename(mnts[0]['Source'])" 2>/dev/null
}

function updateHostName()
{
    HOSTS=/etc/hosts
    HOSTS_TMP=/etc/hosts.tmp

    EXEC="docker exec -i bigfoot bash -c"

    NEW_HOSTNAME="$1"
    HOSTNAME=`$EXEC "hostname"`
    if ! [[ $HOSTNAME =~ ^[a-zA-Z0-9.\-]*$ ]]; then
        HOSTNAME=`hostname`
    fi

    # copy HOSTS to HOSTS_TMP
    $EXEC "cp $HOSTS $HOSTS_TMP"
    # remove entry with hostname
    $EXEC "sed -i \"/$HOSTNAME$/d\" $HOSTS_TMP"
    # add entry with new hostname
    $EXEC "echo -e \"127.0.0.1\t$NEW_HOSTNAME\" >> $HOSTS_TMP"

    echo "Set hostname in bigfoot container"
    $EXEC "hostname '$NEW_HOSTNAME'"
    $EXEC "cat $HOSTS_TMP > $HOSTS"
    $EXEC "rm -f $HOSTS_TMP"
}

function getBootType()
{
    # same code snippet in files/scripts/syncd.sh
    case "$(cat /proc/cmdline)" in
    *SONIC_BOOT_TYPE=warm*)
        TYPE='warm'
        ;;
    *SONIC_BOOT_TYPE=fastfast*)
        TYPE='fastfast'
        ;;
    *SONIC_BOOT_TYPE=fast*|*fast-reboot*)
        TYPE='fast'
        ;;
    *)
        TYPE='cold'
    esac
    echo "${TYPE}"
}

function preStartAction()
{
    : # nothing
}

function postStartAction()
{
    : # nothing
}

start() {
    # Obtain boot type from kernel arguments
    BOOT_TYPE=`getBootType`

    # Obtain our platform as we will mount directories with these names in each docker
    PLATFORM=`sonic-cfggen -H -v DEVICE_METADATA.localhost.platform`
    # Obtain our HWSKU as we will mount directories with these names in each docker
    HWSKU=`sonic-cfggen -d -v 'DEVICE_METADATA["localhost"]["hwsku"]'`
    HOSTNAME=`sonic-cfggen -d -v 'DEVICE_METADATA["localhost"]["hostname"]'`
    if [ -z "$HOSTNAME" ] || ! [[ $HOSTNAME =~ ^[a-zA-Z0-9.\-]*$ ]]; then
        HOSTNAME=`hostname`
    fi

    DOCKERCHECK=`docker inspect --type container bigfoot 2>/dev/null`
    if [ "$?" -eq "0" ]; then
        DOCKERMOUNT=`getMountPoint "$DOCKERCHECK"`
        if [ x"$DOCKERMOUNT" == x"$HWSKU" ]; then
            echo "Starting existing bigfoot container with HWSKU $HWSKU"
            preStartAction
            docker start bigfoot
            CURRENT_HOSTNAME="$(docker exec bigfoot hostname)"
            if [ x"$HOSTNAME" != x"$CURRENT_HOSTNAME" ]; then
                updateHostName "$HOSTNAME"
            fi
            postStartAction
            exit $?
        fi

        # docker created with a different HWSKU, remove and recreate
        echo "Removing obsolete bigfoot container with HWSKU $DOCKERMOUNT"
        docker rm -f bigfoot
    fi
    echo "Creating new bigfoot container with HWSKU $HWSKU"
    docker create --net=host --privileged -t -v /etc/sonic:/etc/sonic:ro  \
        --log-opt max-size=2M --log-opt max-file=5 \
        -v /var/run/redis:/var/run/redis:rw \
        -v /usr/share/sonic/device/$PLATFORM:/usr/share/sonic/platform:ro \
        -v /usr/share/sonic/device/$PLATFORM/$HWSKU:/usr/share/sonic/hwsku:ro \
        --tmpfs /tmp \
        --tmpfs /var/tmp \
        --hostname "$HOSTNAME" \
        --name=bigfoot docker-bigfoot:latest || {
            echo "Failed to docker run" >&1
            exit 4
    }

    preStartAction
    docker start bigfoot
    postStartAction
}

wait() {
    docker wait bigfoot
}

stop() {
    docker stop bigfoot
}

case "$1" in
    start|wait|stop|updateHostName)
        cmd=$1
        shift
        $cmd $@
        ;;
    *)
        echo "Usage: $0 {start|wait|stop|updateHostName new_hostname}"
        exit 1
        ;;
esac
