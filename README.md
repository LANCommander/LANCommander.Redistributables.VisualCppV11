# LANCommander.Redistributables.VisualCppV11

Automatically built LANCommander redistributable import package (`.LCX`) for the
[Visual C++ v11 Redistributable (2012)](https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist).

The Microsoft Visual C++ 2012 runtime (v11.0), required by games built with the
Visual Studio 2012 toolchain — broadly the 2012 to 2014 release window. Without it
a game fails at launch with `MSVCR110.dll is missing`, `MSVCP110.dll was not
found`, or the same for `vccorlib110.dll`, `vcomp110.dll`, `vcamp110.dll`,
`atl110.dll` or `mfc110u.dll`. If a game ships a `_CommonRedist\vcredist\2012\`
or `_Installer\vc\vc2012redist_*` folder, this is the runtime it wants.

This runtime installs **side by side** with every other Visual C++ version. It does
not replace or supersede
[v12 (2013)](https://github.com/LANCommander/LANCommander.Redistributables.VisualCppV12)
or
[v14 (2015–2022)](https://github.com/LANCommander/LANCommander.Redistributables.VisualCppV14),
and a machine can legitimately carry all three.

Both architectures are bundled, at version `11.0.61030.0` — Update 4, the final
Microsoft build. By default each client installs only the one the game's executable
actually needs; set the `Architecture` option to **Both** for .NET AnyCPU games,
which report as 32-bit but run 64-bit — see [Options](#options).

> Microsoft's Visual Studio 2012 REDIST list names `vcredist_x86.exe` and
> `vcredist_x64.exe` as redistributable unmodified, and that is the basis on which
> they are bundled here. The grant carries conditions — including one edition
> carve-out — and the EULA inside the installer contains a clause that sits against
> it. Both are set out in [`LICENSES/NOTICE.md`](LICENSES/NOTICE.md). Read it
> before relying on this package.

## Install it

Download the `.lcx` asset from the [latest release][latest] and import it
through your LANCommander server's **Redistributables** page, or from the CLI:

```
LANCommander.Launcher.CLI Import --Path LANCommander.Redistributables.VisualCppV11-v<version>.lcx --Type Redistributable
```

Then assign it to the games that need it, either from the game's
**Redistributables** field or from this redistributable's **Games** field.

Re-importing a newer release **updates** the existing entry rather than creating a
second one, because the identifiers in `redistributable.yml` are stable across
releases.

Alternatively, import once and let it update itself: the package ships a
`Package` script, which a LANCommander server runs on a schedule to pull new
versions straight from this repository's releases.

[latest]: https://github.com/LANCommander/LANCommander.Redistributables.VisualCppV11/releases/latest

## What is in the package

| Path | |
|---|---|
| `Manifest.yml` | Redistributable metadata, including the embedded option schema |
| `Archives/{guid}` | A ZIP of `vcredist_x86.exe`, `vcredist_x64.exe` and `LICENSE.txt`, extracted into the game's `.lancommander` metadata directory |
| `Scripts/{guid}` | One entry per PowerShell script |

## Options

| Option | Type | Default | Description |
|---|---|---|---|
| `Architecture` | choice — `both`, `auto`, `x86`, `x64` | `auto` | Which runtime to install. The default, **Match the game executable**, reads the game's PE header and installs only the runtime it actually needs. There is one case it gets wrong: a .NET AnyCPU executable reports as 32-bit even though it runs 64-bit, so set those games to **Both**. **Both** is also the right answer whenever you are unsure — 64-bit Windows still needs the x86 runtime because most games of this era are 32-bit, and installing both is never wrong, only occasionally more than necessary. |

Administrators can override this per game from the game's **Redistributables**
page. Values resolve as schema default, then per-game value, then per-action
override.

## How this repository works

| File | Purpose |
|---|---|
| `redistributable.yml` | Identity, download links, stable script GUIDs |
| `source.ps1` | Downloads both installers under their upstream names and reads the version off the PE resource |
| `Schema.Overlay.yml` | The whole option schema, written by hand — there is no config file to parse |
| `OptionSchema.yml` | Built from the overlay. Do not edit by hand |
| `Scripts/*.ps1` | Client-side and server-side scripts |
| `LICENSES/` | Upstream attribution and license text |

`OptionSchema.yml` is generated, and the build fails if the committed copy does
not match what the overlay produces. To regenerate it locally:

```powershell
Import-Module <path-to>/LANCommander.Redistributables/module/LANCommander.Redistributables
Invoke-RedistributableBuild -RepositoryPath . -UpdateSchema
```

### How detection and install work

`DetectInstall` reads `Version` and `Installed` from
`HKLM\SOFTWARE\Microsoft\VisualStudio\11.0\VC\Runtimes\{x86,x64}` and from the
`WOW6432Node` path, because which root a runtime is visible under depends both on
registry redirection and on the bitness of the host PowerShell. For this version
that is not a formality: on a 64-bit host, 2012 registers **both** architectures
under `WOW6432Node` and leaves the native path absent altogether, unlike v14 which
mirrors x64 into both. An empty native key is normal here, not a fault.

It reports "installed" only when every selected architecture is present *and* at
least as new as the build this package carries, because Microsoft's installer
refuses to downgrade and returns an error when a newer runtime is already present.
The registry writes `v11.0.61030.00` while the manifest carries `11.0.61030.0`, so
both sides are reduced to major.minor.build before they are compared.

`Install` runs each installer with `/install /quiet /norestart` and treats
`1638` (a newer version is already installed, also seen as `0x80070666`), `3010`
and `1641` (reboot pending or initiated) as success alongside `0`.

`Uninstall` deliberately does nothing. The runtime is shared machine-wide and
other software depends on it.

### Why the upstream check never reports anything

Visual Studio 2012 left extended support on 10 January 2023 and the runtime is
pinned to `11.0.61030.0`, so the scheduled `check-upstream` workflow runs daily and
always finds the same version. That is correct rather than broken — it stays in
place in case Microsoft reissues a security update.

Unlike the 2013 and v14 packages there are no `aka.ms` permalinks for 2012; the
download links are raw `download.microsoft.com` paths, which also means they cannot
self-heal if Microsoft reorganises the CDN. Note that the path segment is not
uniform upstream: x86 and x64 are documented under `VSU_4`, while
`VSU_4/vcredist_arm.exe` is a 404 and ARM is only reachable under `VSU4`.

Both workflows pin `runs_on: windows-latest`. `source.ps1` reads the version out of
the installer's PE resource, and .NET's Unix implementation of `FileVersionInfo`
returns an empty string for a perfectly valid Windows executable rather than
failing, so on the default Linux runner every version would silently come back
blank.

## Licensing

The scripts and workflows here are MIT licensed. The redistributed payload is not
ours — see [`LICENSES/NOTICE.md`](LICENSES/NOTICE.md) for attribution, the full
terms, and the reasoning behind how this package is distributed.
