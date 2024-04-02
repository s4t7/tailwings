Tailscale Tailwings
===================

This is a container image that runs a Tailscale exit node and proxy servers
to work as a 'personal VPN' service, that can be deployed using Fly.io or
other container hosting platforms.

This is a fork of [patte/fly-tailscale-exit](https://github.com/patte/fly-tailscale-exit/)
with some minor fixes and additions, like Squid and Dante to acts as proxies.


Usage
-----
The original [documentation](./docs.md) can help you to set this up on Fly.io.

To use the proxies, you can use the `tailscale ip` that has been given to the node;
  * port `3214` is the Squid HTTP proxy
  * port `3215` is the Dante SOCKS5 proxy

You can also use `ssh` to connect to the node with the `-D` option or `sshuttle`.
Authentication is handled by Tailscale SSH, and currently expects `root` as user.

On port `53` it runs dnsmasq as a forwarder.


Deploy
------

Use the [Gitpod workspace](https://gitpod.io/#https://github.com/spotsnel/tailscale-tailwings)
to help with the deployment to Fly.io, following the original documentation and the provided
`fly.toml`.

Otherwise, you can use `podman` or `docker` to deploy the `Containerfile` that is
included, or use:

```sh
$ podman run -d \
   --name=tailwings \
   --env=TAILSCALE_AUTH_KEY=tskey-... \
   --cap-add=NET_ADMIN \
   --cap-add=NET_RAW \
   --device=/dev/net/tun \ 
  ghcr.io/saahirlol/hs-tailwings:main
```

