# Lists for Nftlist

The lists of IP servers of a popular services, such as GitHub, Cloudflare, etc.

It's a simple plain text list with one IPv4/IPv6 address per line. Comments starts with `#`, a list can have empty lines for readability.

The list is mainained for [nftlist](https://github.com/tools200ms/nftlist) tool.

Covered services: 
- Bitbucket/Atlassian IPs
- Cloudflare IP Ranges
- GitHub IP-range
- Nitropack.io IP list

## File name convention

List name convention is as follows: 
```
<service>-<label>-<ipv4|ipv6|inet>.list
# or 
<service>-<ipv4|ipv6|inet>.list
```

- **service** name: github, bitbucket, etc.
- **label (optional)** that is indicating what kind of IP addresses list holds, e.g.: outbond, inbound, hooks.
- **ipv4|ipv6|inet** indicates IP family which file contains: 
  - only **ipv4** addresses
  - only **ipv6** addresses
  - mixed (**inet**) IPv4 and IPv6.

Lists are acequired directly from service provider's website or via API if provided.

# References

[NFT List](https://github.com/tools200ms/nftlist) - complementing tool for blocking/allowing network traffic.
