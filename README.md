# Smokeping ARMv5 Container

Most public Smokeping images do not support linux/arm/v5 and are often too heavy for devices like MikroTik hEX

This project offers a lightweight, optimized Smokeping image for ARMv5, built on debian:bookworm-slim to ensure a minimal, stable, and fully featured runtime for constrained embedded systems

---

## Registry Information

This image is published on **GitHub Container Registry (GHCR)**

Set your MikroTik registry to:

```
https://ghcr.io
```

Then pull the image:

```
raw-network/smokeping-armv5:latest
```

---

> **Note:** Ensure you set the correct timezone using the `TZ` environment variable (e.g., `TZ=Asia/Jakarta`, default `TZ=UTC`). This is required for accurate graph timestamps and RRD logging

---
## Directories & Persistence

Since this image uses standard system paths, you should mount the following directories to persist your data and configurations:

| Container Path         | Description                                                                             |
| ---------------------- | --------------------------------------------------------------------------------------- |
| `/config`              | Stores Smokeping configs (Targets, Probes, General).                                    |
| `/data`                | Stores RRD graph databases. Map this to avoid losing graph history.                     |

### Example Docker Compose Volume Mapping:

---

To modify your ping targets, edit:
```
./config/Targets
```

Then restart the container

---

## Original Source

Smokeping – https://oss.oetiker.ch/smokeping/

License: **GPL**

---

## Exposed Ports

| Port | Protocol | Description      |
| ---- | -------- | ---------------- |
| 80   | TCP      | Smokeping Web UI |

---

## Enjoy

If this helps you monitor latency on low‑end ARMv5 devices, enjoy this lightweight image!