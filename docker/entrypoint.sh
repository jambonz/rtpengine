#!/bin/bash
set -e

PATH=/usr/local/bin:$PATH

case $CLOUD in
  gcp)
    LOCAL_IP=$(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip)
    PUBLIC_IP=$(curl -s -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip)
    ;;
  aws)
    # Ask for an IMDSv2 token first and use it when we get one. A node with
    # http_tokens=required -- the default the jambonz EKS terraform sets, and
    # increasingly the default everywhere -- answers every unauthenticated
    # metadata request with 401 and an empty body. Without this, PUBLIC_IP and
    # LOCAL_IP both come back empty, MY_IP falls back to `hostname -I`, and
    # rtpengine ends up with "interface=public/<private ip>" and no advertised
    # address: it then puts a VPC-private address in the SDP, the far end sends
    # RTP nowhere, and every call is one-way silence.
    # The token PUT is harmless on an IMDSv1 node, so there is one code path.
    TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
              -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" || true)
    if [ -n "$TOKEN" ]; then
      LOCAL_IP=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/local-ipv4)
      PUBLIC_IP=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/public-ipv4)
    else
      LOCAL_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
      PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
    fi
    ;;
  scaleway)
    LOCAL_IP=$(curl -s --local-port 1-1024 http://169.254.42.42/conf | grep PRIVATE_IP | cut -d = -f 2)
    PUBLIC_IP=$(curl -s --local-port 1-1024 http://169.254.42.42/conf | grep PUBLIC_IP_ADDRESS | cut -d = -f 2)
    ;;
  digitalocean)
    LOCAL_IP=$(curl -s http://169.254.169.254/metadata/v1/interfaces/private/0/ipv4/address)
    PUBLIC_IP=$(curl -s http://169.254.169.254/metadata/v1/interfaces/public/0/ipv4/address)
    ;;
  azure)
    LOCAL_IP=$(curl -s -H Metadata:true --noproxy "*" "http://169.254.169.254/metadata/instance/network/interface/0/ipv4/ipAddress/0/privateIpAddress?api-version=2017-08-01&format=text")
    PUBLIC_IP=$(curl -s -H Metadata:true --noproxy "*" "http://169.254.169.254/metadata/instance/network/interface/0/ipv4/ipAddress/0/publicIpAddress?api-version=2017-08-01&format=text")

    # On AKS the instance metadata above reports publicIpAddress as an empty
    # string for every ipConfig, even though the node does have a public IP: it
    # comes from the VMSS node-public-IP feature, which instance metadata does
    # not expose. Verified on a live AKS node -- the whole ipv4 block came back
    # as [{"privateIpAddress":"10.0.3.4","publicIpAddress":""}, ...] while the
    # node was reachable on 4.154.77.176.
    #
    # The loadbalancer metadata endpoint does report it, which is how
    # drachtio-server's entrypoint has always found it (LB_IMDS). Without this,
    # rtpengine comes up as "interface=public/<private ip>" with no advertised
    # address, puts a VNet-private address in the SDP, and every call is one-way
    # silence.
    #
    # Parsed with sed rather than jq: unlike the drachtio image, this one has no
    # jq, and one metadata lookup does not justify the dependency. Only the
    # publicIpAddresses array is inspected -- inboundRules further down the same
    # document also has a frontendIpAddress, which must not be matched.
    if [ -z "$PUBLIC_IP" ]; then
      LB_META=$(curl -s -H Metadata:true --noproxy "*" \
        "http://169.254.169.254/metadata/loadbalancer?api-version=2020-10-01" || true)
      case "$LB_META" in
        *'"publicIpAddresses"'*)
          LB_PUBS=${LB_META#*\"publicIpAddresses\":[}
          LB_PUBS=${LB_PUBS%%]*}
          LB_PUBLIC=$(echo "$LB_PUBS" | sed -n 's/.*"frontendIpAddress":"\([^"]*\)".*/\1/p' | head -1)
          LB_PRIVATE=$(echo "$LB_PUBS" | sed -n 's/.*"privateIpAddress":"\([^"]*\)".*/\1/p' | head -1)
          if [ -n "$LB_PUBLIC" ]; then
            PUBLIC_IP="$LB_PUBLIC"
            [ -n "$LB_PRIVATE" ] && LOCAL_IP="$LB_PRIVATE"
          fi
          ;;
      esac
    fi
    ;;
  *)
    ;;
esac

if [ -n "$PUBLIC_IP" ]; then
  MY_IP="$LOCAL_IP"!"$PUBLIC_IP"
elif [ -n "$LOCAL_IP" ]; then
  MY_IP="$LOCAL_IP"
else
  MY_IP=$(hostname -I | cut -f1 -d' ')
  LOCAL_IP="$MY_IP"
fi

sed -i -e "s:\(interface=.*\)MY_IP:\1$MY_IP:g" rtpengine.conf
sed -i -e "s/MY_IP/$LOCAL_IP/g" rtpengine.conf

if [ "$1" = 'rtpengine' ]; then
  shift
  exec rtpengine --config-file rtpengine.conf  "$@"
fi

exec "$@"
