# RWA VPS Panel installer

Install the private RWA VPS Panel on a fresh Ubuntu 24.04 VPS:

```bash
curl -fsSL https://raw.githubusercontent.com/ShentoHendriks/rwa-vps-installer/main/install.sh | sudo bash
```

The installer prompts securely for a GitHub token with **Contents: Read** access to `ShentoHendriks/rwa-vps-panel`, followed by the panel domain and Let's Encrypt email address. No credentials are included in the command or saved in shell history.

The token is used only to clone the private panel source. The installer removes it from the installed Git remote immediately afterward.
