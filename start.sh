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

# --tun=userspace-networking --socks5-server=localhost:3215
/app/tailscaled --verbose=1 --port 41641 &
sleep 5
if [ ! -S /var/run/tailscale/tailscaled.sock ]; then
    echo "tailscaled.sock does not exist. exit!"
    exit 1
fi
### Get actual city names

region_code=${FLY_REGION}


# Map of fly.io region codes to lowercase city names without country or province
declare -A region_map
region-map["ams"]="amsterdam"
region-map["arn"]="stockholm"
region-map["atl"]="atlanta"
region-map["bog"]="bogotá"
region-map["bom"]="mumbai"
region-map["bos"]="boston"
region-map["cdg"]="paris"
region-map["den"]="denver"
region-map["dfw"]="dallas"
region-map["ewr"]="secaucus"
region-map["eze"]="ezeiza"
region-map["fra"]="frankfurt"
region-map["gdl"]="guadalajara"
region-map["gig"]="rio-de-janeiro"
region-map["gru"]="sao-paulo"
region-map["hkg"]="hong-kong"
region-map["iad"]="ashburn"
region-map["jnb"]="johannesburg"
region-map["lax"]="los-angeles"
region-map["lhr"]="london"
region-map["mad"]="madrid"
region-map["mia"]="miami"
region-map["nrt"]="tokyo"
region-map["ord"]="chicago"
region-map["otp"]="bucharest"
region-map["phx"]="phoenix"
region-map["qro"]="querétaro"
region-map["scl"]="santiago"
region-map["sea"]="seattle"
region-map["sin"]="singapore"
region-map["sjc"]="san-jose"
region-map["syd"]="sydney"
region-map["waw"]="warsaw"
region-map["yul"]="montreal"
region-map["yyz"]="toronto"


city_name=${region_map[${region_code,,}]}

#end of this

until /app/tailscale up \
    --login-server=${HS} \
    --authkey=${TAILSCALE_AUTH_KEY} \
    --hostname=${city_name}-flyio \
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
