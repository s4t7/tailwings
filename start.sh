#!/bin/sh

echo 'Starting up Tailscale...'

# error: adding [-i tailscale0 -j MARK --set-mark 0x40000] in v4/filter/ts-forward: running [/sbin/iptables -t filter -A ts-forward -i tailscale0 -j MARK --set-mark 0x40000 --wait]: exit status 2: iptables v1.8.6 (legacy): unknown option "--set-mark"
modprobe xt_mark

echo 'net.ipv4.ip_forward = 1' | tee -a /etc/sysctl.conf
echo 'net.ipv6.conf.all.forwarding = 1' | tee -a /etc/sysctl.conf
#echo 'net.ipv6.conf.all.disable_policy = 1' | tee -a /etc/sysctl.conf
sysctl -p /etc/sysctl.conf

iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
ip6tables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# Function to de-abbreviate a region ID to city
deabbreviate() {
    local region_id=$1
    case $region_id in
        ams) echo "amsterdam" ;;
        arn) echo "stockholm" ;;
        atl) echo "atlanta" ;;
        bog) echo "colombia-bogota" ;;
        bom) echo "mumbai" ;;
        bos) echo "boston" ;;
        cdg) echo "paris" ;;
        den) echo "denver" ;;
        dfw) echo "dallas" ;;
        ewr) echo "new-york-city" ;;
        eze) echo "argentina-ezeiza" ;;
        fra) echo "frankfurt" ;;
        gdl) echo "mexico-guadalajara" ;;
        gig) echo "rio-de-janeiro" ;;
        gru) echo "sao-paulo" ;;
        hkg) echo "hong-kong" ;;
        iad) echo "virginia-ashburn" ;;
        jnb) echo "johannesburg" ;;
        lax) echo "cali-los-angeles" ;;
        lhr) echo "london" ;;
        mad) echo "madrid" ;;
        mia) echo "miami" ;;
        nrt) echo "tokyo" ;;
        ord) echo "chicago" ;;
        otp) echo "romania-bucharest" ;;
        phx) echo "phoenix" ;;
        qro) echo "mexico-queretaro" ;;
        scl) echo "chile-santiago" ;;
        sea) echo "seattle" ;;
        sin) echo "singapore" ;;
        sjc) echo "cali-san-jose" ;;
        syd) echo "sydney" ;;
        waw) echo "warsaw" ;;
        yul) echo "montreal" ;;
        yyz) echo "toronto" ;;
        *) echo "unknown" ;;
    esac
}


# Get actual city name
region_code=${FLY_REGION}
city=$(deabbreviate $region_code)

echo "Region code: $region_code"
echo "City: $city"

# Start tailscaled
/app/tailscaled --verbose=1 --port 41641 &
sleep 5

if [ ! -S /var/run/tailscale/tailscaled.sock ]; then
    echo "tailscaled.sock does not exist. exit!"
    exit 1
fi

until /app/tailscale up \
    --login-server=${HS} \
    --authkey=${TAILSCALE_AUTH_KEY} \
    --hostname=flyio-${city} \
    --advertise-exit-node \
    --ssh
do
    sleep 0.1
done

echo 'Tailscale started'

echo 'Starting Squid...'

squid &

echo 'Squid started'

echo 'Starting Dante...'

sockd &

echo 'Dante started'

echo 'Starting dnsmasq...'

dnsmasq &

echo 'dnsmasq started'

sleep infinity
