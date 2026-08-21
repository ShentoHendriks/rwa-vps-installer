# RWA VPS Panel installer

Install the complete RWA VPS Panel on a fresh Ubuntu 24.04 VPS:

```bash
curl -fsSL https://raw.githubusercontent.com/ShentoHendriks/rwa-vps-installer/main/install.sh | sudo bash
```

No GitHub account, token, repository access, or extra command arguments are required. The installer downloads the public, versioned panel release and asks only for:

- the panel domain, which must already point to the VPS;
- the email address used for the Let's Encrypt certificate.

When it completes, open `https://your-panel-domain/setup` and create the owner account.

## Releases

The installer pins the release version in `install.sh`. The source archive it downloads is public so a fresh VPS can install it without credentials.
