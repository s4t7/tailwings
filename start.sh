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


# Correction of syntax error in map declaration and use FLY_REGION directly
declare -A region_map=(
    [ams]="amsterdam" [arn]="stockholm" [atl]="atlanta" [bog]="bogotá"
    [bom]="mumbai" [bos]="boston" [cdg]="paris" [den]="denver"
    [dfw]="dallas" [ewr]="secaucus" [eze]="ezeiza" [fra]="frankfurt"
    [gdl]="guadalajara" [gig]="rio-de-janeiro" [gru]="sao-paulo"
    [hkg]="hong-kong" [iad]="ashburn" [jnb]="johannesburg" [lax]="los-angeles"
    [lhr]="london" [mad]="madrid" [mia]="miami" [nrt]="tokyo"
    [ord]="chicago" [otp]="bucharest" [phx]="phoenix" [qro]="querétaro"
    [scl]="santiago" [sea]="seattle" [sin]="singapore" [sjc]="san-jose"
    [syd]="sydney" [waw]="warsaw" [yul]="montreal" [yyz]="toronto"
)

city_name=${region_map[${FLY_REGION,,}]}

# Tailscale up command in a loop to handle potential failures

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
