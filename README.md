# RWA VPS Panel installer

Install the complete RWA VPS Panel on a fresh Ubuntu 24.04 VPS:

```bash
curl -fsSL https://github.com/ShentoHendriks/rwa-vps-installer/releases/latest/download/install.sh | sudo bash
```

The command uses the current versioned release directly, so it is not affected by branch-file caching. It requires no GitHub account, token, repository access, arguments, or interactive answers.

The installer detects the VPS public IPv4 address and opens the panel at `http://VPS_IP/setup`. The panel uses HTTP because a TLS certificate cannot be issued for a generic IP address.

## Releases

Each release includes the panel archive and a matching `install.sh` asset. Run `npm run publish` from the private development repository to publish the next release.
