# macOS "System Data" Cleanup — Sourced Research Reference

Factual backbone for the cleanup utility. Every cleanable location carries a safety classification and at least one authoritative source. This file exists to prevent hallucinated paths/behaviors in later milestones (M1 scan → M2 delete → M3 delegated cleanup). Treat it as the source of truth for the safety classifier.

> Scope note: M0 (this change) implements none of this. It is recorded now so the architecture and the 5-tier safety model are grounded from the start.

---

## 1. What "System Data" actually is

In macOS Storage settings, "System Data" (formerly "Other") is an **aggregation**, not a folder — everything not recognized as Apps, Photos, Mail, Music, Documents, or macOS. In practice it is dominated by:

- **APFS local snapshots** (Time Machine local snapshots) — usually the single biggest contributor
- **Caches** (`~/Library/Caches`, `/Library/Caches`, browser/app caches)
- **Application Support data** (incl. iOS backups, Docker/VM disk images)
- **Logs**, **sleep image / swap**, **Mail/Messages attachments**, **Trash**, stray temp files

Sources: [MacPaw – purgeable space](https://macpaw.com/how-to/purgeable-space-on-macos), [DaisyDisk – Purgeable space](https://daisydiskapp.com/guide/4/en/PurgeableSpace/), [Michael Tsai – Purgeable Disk Space](https://mjtsai.com/blog/2025/03/10/purgeable-disk-space/)

---

## 2. The 5-tier safety model

| Tier | Meaning | UX treatment |
|---|---|---|
| **SAFE** | Regenerable / disposable, no user data | Preset-eligible, simple confirm |
| **CACHE** | Safe but apps regenerate; transient slowdown after | Preset-eligible + "will regenerate" warning |
| **DELEGATED** | Owner tool manages the data; never raw-delete | Run the owner's CLI (tmutil/docker/brew/…); M3 |
| **RISKY** | User-owned & often irreplaceable | Manual-only, RED type-to-confirm; never a one-click preset |
| **NEVER** | SIP/SSV/OS-managed; kernel blocks writes | Not shown as cleanable; greyed + "why" tooltip |

---

## 3. Location reference table

| Path | What accumulates / why it bloats | Tier | Source |
|---|---|---|---|
| `~/Library/Caches` | Per-user app caches; regenerated on use | **CACHE** | [iBoysoft](https://iboysoft.com/wiki/library-caches-mac.html), [AppleInsider](https://appleinsider.com/inside/macos/tips/which-hidden-files-you-can-safely-delete-from-your-mac) |
| `/Library/Caches` | System-wide/shared caches; regenerated (admin) | **CACHE** | [AppleInsider](https://appleinsider.com/inside/macos/tips/which-hidden-files-you-can-safely-delete-from-your-mac) |
| `~/Library/Application Support` | Per-app data; *leftovers from uninstalled apps* bloat | **RISKY** | [iBoysoft](https://iboysoft.com/wiki/mac-containers-folder.html), [AppleInsider](https://appleinsider.com/inside/macos/tips/which-hidden-files-you-can-safely-delete-from-your-mac) |
| APFS local snapshots (`tmutil`) | Time Machine local snapshots; grow with disk churn | **DELEGATED** (tmutil only) | [Eclectic Light – tmutil](https://eclecticlight.co/2020/01/22/time-machine-11-tmutil/), [Apple – Disk Utility snapshots](https://support.apple.com/guide/disk-utility/view-apfs-snapshots-dskuf82354dc/mac) |
| `~/Library/Developer/Xcode/DerivedData` | Build artifacts/indexes; 5–20+ GB; regenerable | **SAFE** | [Cluttered](https://www.cluttered.dev/blog/xcode-derived-data) |
| `~/Library/Developer/Xcode/iOS DeviceSupport` | Per-iOS-version symbols; 2–5 GB each | **CACHE** | [swiftyplace](https://www.swiftyplace.com/blog/how-to-clean-xcode-on-your-mac) |
| `~/Library/Developer/CoreSimulator` | Simulator runtime images + device data | **CACHE** | [swiftyplace](https://www.swiftyplace.com/blog/how-to-clean-xcode-on-your-mac) |
| `~/Library/Developer/Xcode/Archives` | App archives for App Store/TestFlight | **RISKY** (not regenerable) | [DiskCleaner](https://www.diskcleaner.pro/blog/is-it-safe-to-delete-developer-data-on-mac/) |
| `~/Library/Containers` | Sandboxed app data; live for active apps | **RISKY** (removed apps only) | [iBoysoft](https://iboysoft.com/wiki/mac-containers-folder.html) |
| `~/Library/Group Containers` | Shared data across multiple apps | **RISKY** (one delete breaks several) | [iBoysoft](https://iboysoft.com/wiki/mac-containers-folder.html) |
| Mail attachments/downloads | Saved attachments accumulate (behind Full Disk Access) | **RISKY** | [Apple Dev Forums – Mail DB needs FDA](https://developer.apple.com/forums/thread/124895) |
| `~/Library/Messages/Attachments` | Photos/video sent & received; large | **RISKY** (breaks Messages history) | [Apple – manage storage](https://support.apple.com/en-us/108809) |
| `~/Library/Application Support/MobileSync/Backup` | Full iOS device backups; never auto-overwritten | **RISKY** (only local copy) | [Apple – locate/manage backups](https://support.apple.com/en-us/108809) |
| Photos library cache | Thumbnails/derived images; regenerable | **CACHE** | [Apple Community – Photos cache](https://discussions.apple.com/thread/7849063) |
| `~/Library/Containers/com.apple.Safari/Data/Library/Caches` | Web cache; regenerates on browse | **CACHE** | [Apple Community – Safari cache](https://discussions.apple.com/thread/8571352) |
| `~/Library/Caches/Google/Chrome` (+ profile `Cache`) | Web cache | **CACHE** | [iBoysoft](https://iboysoft.com/wiki/library-caches-mac.html) |
| Docker `…/com.docker.docker/Data/vms/0/data/Docker.raw` | Single VM disk image; grows, never auto-shrinks | **DELEGATED** (`docker system prune`; never rm raw) | [Docker Mac FAQ](https://docs.docker.com/desktop/troubleshoot-and-support/faqs/macfaqs/) |
| `~/.orbstack` | OrbStack VM disk | **DELEGATED** (manage via OrbStack) | [Webology notes](https://micro.webology.dev/2024/04/08/docker-and-orbstack-disk-cleanup/) |
| `~/Downloads` | User downloads pile up | **RISKY** (user data; list, never auto-delete) | general |
| `~/.Trash` | Deleted files awaiting purge | **SAFE** (empty Trash) | [AppleInsider](https://appleinsider.com/inside/macos/tips/which-hidden-files-you-can-safely-delete-from-your-mac) |
| `node_modules` (per project) | Reinstallable deps; huge in aggregate | **SAFE** (`npm install` regenerates) | dev practice |
| `~/.npm/_cacache` | Downloaded packages | **CACHE** / **DELEGATED** (`npm cache clean --force`) | [DeepClean](https://deepclean.app/blog/clear-npm-yarn-pnpm-cache-mac) |
| `~/Library/Caches/Yarn` (v1), `~/.yarn/berry/cache` (v2+) | Downloaded packages | **CACHE** / **DELEGATED** | [Yarn docs](https://yarnpkg.com/cli/cache/clean) |
| `~/Library/pnpm/store` | Content-addressed package store | **CACHE** / **DELEGATED** | [DeepClean](https://deepclean.app/blog/clear-npm-yarn-pnpm-cache-mac) |
| `~/Library/Caches/pip` | HTTP cache + built wheels | **CACHE** / **DELEGATED** (`pip cache purge`) | [pip docs](https://pip.pypa.io/en/stable/topics/caching/) |
| `~/.cargo/registry`, `~/.cargo/git` | Crate sources + git checkouts; 50 GB+ | **CACHE** / **DELEGATED** (`cargo-cache`) | [Rust Blog](https://blog.rust-lang.org/2023/12/11/cargo-cache-cleaning/) |
| `~/Library/Caches/Homebrew` | Downloaded bottles/casks | **DELEGATED** (`brew cleanup --prune=all`) | [Homebrew #3784](https://github.com/Homebrew/brew/issues/3784), [docs.brew.sh](https://docs.brew.sh/rubydoc/Homebrew/Cleanup.html) |
| `~/Library/Logs` | Per-user app/diagnostic logs; regenerated | **CACHE/SAFE** | [AppleInsider](https://appleinsider.com/inside/macos/tips/which-hidden-files-you-can-safely-delete-from-your-mac) |
| `/private/var/log` (`/var/log`) | System logs; rotated by `newsyslog` | **RISKY** (let macOS rotate; needs root) | [Apple SIP guide](https://support.apple.com/guide/security/system-integrity-protection-secb7ea06b49/web) |
| `/private/var/vm` (sleepimage, swapfile) | Hibernation image + RAM swap | **NEVER** (OS-managed; delete can hang/corrupt) | [Apple Community – /var/vm](https://discussions.apple.com/thread/3114607) |
| `/System`, `/usr` (not `/usr/local`), `/bin`, `/sbin`, `/var` | OS system files | **NEVER** (SIP; root cannot write) | [Apple SIP guide](https://support.apple.com/guide/security/system-integrity-protection-secb7ea06b49/web), [HackTricks – SIP](https://hacktricks.wiki/en/macos-hardening/macos-security-and-privilege-escalation/macos-security-protections/macos-sip.html) |
| `.DS_Store` files | Finder view metadata per folder | **SAFE** (Finder recreates) | [Microsoft Support](https://support.microsoft.com/en-us/office/remove-ds-store-files-on-macos-d2f8dca0-740a-4f7e-89b9-5b2cbbc50386) |

---

## 4. Per-item implementer notes

- **APFS local snapshots** — never delete raw blocks; contents aren't user-scannable. Use `tmutil listlocalsnapshots /`, `tmutil deletelocalsnapshots <date>`, or `tmutil thinlocalsnapshots <mount> <purgeBytes> <urgency 1-4>`. macOS already auto-thins snapshots >~24h and under space pressure. ([Eclectic Light](https://eclecticlight.co/2020/01/22/time-machine-11-tmutil/))
- **Docker.raw never auto-shrinks** — reclaim via `docker system prune`/`docker image prune` or Docker Desktop → Resources; deleting the raw destroys all images/containers/volumes. ([Docker FAQ](https://docs.docker.com/desktop/troubleshoot-and-support/faqs/macfaqs/))
- **iOS backups pile up** — old device backups are never overwritten; treat as user data, surface for review, never auto-delete. ([Apple](https://support.apple.com/en-us/108809))
- **Containers vs Group Containers** — only remove a Container subfolder for a definitively uninstalled app; Group Containers are shared and one delete can break several apps. ([iBoysoft](https://iboysoft.com/wiki/mac-containers-folder.html))
- **Package-manager caches are the safest big dev wins** — prefer each tool's own cleanup command over `rm -rf` so internal indexes stay consistent. This is the core reason the **DELEGATED** tier exists.

---

## 5. Why modern macOS makes this hard

- **Purgeable space**: macOS reports reclaimable blocks (snapshots, caches, sleep image, evictable cloud files) as *purgeable*, not free, and lets it accumulate (up to ~80% of disk) until an app needs space. Explains why deleting files sometimes frees nothing visible. ([MacPaw](https://macpaw.com/how-to/purgeable-space-on-macos), [DaisyDisk](https://daisydiskapp.com/guide/4/en/PurgeableSpace/), [Michael Tsai](https://mjtsai.com/blog/2025/03/10/purgeable-disk-space/))
- **Snapshots pin old blocks**: a snapshot looks tiny but pins changed blocks; space returns only after `tmutil` thins/deletes it. Contents are invisible to file scanners. ([DaisyDisk](https://daisydiskapp.com/guide/4/en/Snapshots/))
- **Sealed read-only system volume**: since Catalina the boot disk splits into read-only System + writable Data volumes joined by firmlinks; since Big Sur the System volume is a mounted snapshot of a cryptographically **Signed System Volume (SSV)** — every file is SHA-256-verified and any modification breaks the seal and prevents boot. System files are cryptographically immutable, not merely permission-protected. ([Eclectic Light – Catalina volumes](https://eclecticlight.co/2020/01/23/catalina-boot-volumes/), [Eclectic Light – SSV](https://eclecticlight.co/2020/06/25/big-surs-signed-system-volume-added-security-protection/), [Apple – SSV security](https://support.apple.com/guide/security/signed-system-volume-security-secd698747c9/web))

---

## 6. SIP — what it protects, why `sudo` can't help

System Integrity Protection applies mandatory access controls to **every** process "regardless of whether that process is running sandboxed or with administrative privileges" — even `root` is denied write to protected locations. Protected: `/System`, `/usr` (but **not** `/usr/local`), `/bin`, `/sbin`, `/var`, Apple-preinstalled apps. Writable third-party locations: `/Applications`, `/Library`, `/usr/local`. A cleanup tool **physically cannot** touch these even with `sudo` — the kernel blocks the syscall — so they must never be surfaced as cleanable. ([Apple – SIP](https://support.apple.com/guide/security/system-integrity-protection-secb7ea06b49/web), [HackTricks – SIP](https://hacktricks.wiki/en/macos-hardening/macos-security-and-privilege-escalation/macos-security-protections/macos-sip.html))

---

## 7. Sandbox / Full Disk Access implications

- **Sandboxing is effectively incompatible** with a whole-disk cleaner: a sandboxed app sees only its container + a small allowlist unless the user grants per-path access. → Ship **unsandboxed**, distributed outside the Mac App Store. ([Apple – App Sandbox file access](https://developer.apple.com/documentation/security/accessing-files-from-the-macos-app-sandbox))
- **Full Disk Access (TCC)**: even unsandboxed, reading Mail, Messages, Safari data, `MobileSync` backups, Time Machine data requires the user to grant **Full Disk Access** in System Settings → Privacy & Security. **It cannot be requested programmatically.** → M1 needs an onboarding flow that explains it, deep-links to the pane, and degrades gracefully when absent. ([Apple Dev Forums – Mail DB needs FDA](https://developer.apple.com/forums/thread/124895), [file system permissions](https://developer.apple.com/forums/thread/678819))
- **Recommendation**: unsandboxed + notarized (notarization later), prompt for FDA, degrade gracefully, never claim to clean SIP/SSV/`var/vm`.

---

## 8. To verify in-product

- Safari's cache moved into its sandbox container (`~/Library/Containers/com.apple.Safari/Data/Library/Caches`) on modern macOS; the legacy `~/Library/Caches/com.apple.Safari` may or may not exist by version — a robust scanner should check both.

---

### Primary sources
Apple: [SIP](https://support.apple.com/guide/security/system-integrity-protection-secb7ea06b49/web) · [Signed System Volume](https://support.apple.com/guide/security/signed-system-volume-security-secd698747c9/web) · [View APFS snapshots](https://support.apple.com/guide/disk-utility/view-apfs-snapshots-dskuf82354dc/mac) · [Manage iPhone backups](https://support.apple.com/en-us/108809) · [App Sandbox file access](https://developer.apple.com/documentation/security/accessing-files-from-the-macos-app-sandbox) · [Mail DB / FDA forum](https://developer.apple.com/forums/thread/124895)
Howard Oakley / Eclectic Light: [tmutil](https://eclecticlight.co/2020/01/22/time-machine-11-tmutil/) · [Catalina boot volumes](https://eclecticlight.co/2020/01/23/catalina-boot-volumes/) · [SSV](https://eclecticlight.co/2020/06/25/big-surs-signed-system-volume-added-security-protection/)
Tooling: [Docker Mac FAQ](https://docs.docker.com/desktop/troubleshoot-and-support/faqs/macfaqs/) · [Homebrew Cleanup](https://docs.brew.sh/rubydoc/Homebrew/Cleanup.html) · [pip caching](https://pip.pypa.io/en/stable/topics/caching/) · [Cargo cache cleaning](https://blog.rust-lang.org/2023/12/11/cargo-cache-cleaning/) · [Yarn cache clean](https://yarnpkg.com/cli/cache/clean)
Space concepts: [DaisyDisk purgeable](https://daisydiskapp.com/guide/4/en/PurgeableSpace/) · [DaisyDisk snapshots](https://daisydiskapp.com/guide/4/en/Snapshots/) · [MacPaw purgeable](https://macpaw.com/how-to/purgeable-space-on-macos) · [Michael Tsai](https://mjtsai.com/blog/2025/03/10/purgeable-disk-space/)
