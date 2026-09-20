# Attribution and licensing

This repository contains two separately licensed things. Keeping them distinct
matters, because only one of them is ours to license.

## What we authored

The packaging scripts, workflows, option schema, curation overlay and
documentation in this repository are copyright (c) 2026 LANCommander and are
released under the MIT License, in `LICENSE`.

## What we redistribute

The published `.LCX` package contains `vcredist_x86.exe` and `vcredist_x64.exe`,
which we did not author and do not license. Those files remain under their own
terms:

| | |
|---|---|
| Project | Visual C++ v11 Redistributable (2012) |
| Homepage | https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist |
| Copyright | (c) Microsoft Corporation |
| License | Microsoft Software License Terms — Microsoft Visual C++ 2012 Runtime Libraries (EULAID: VS2012_RTM_VC.1_ENU) |
| Version | 11.0.61030.0 |

The full terms are in `UPSTREAM-LICENSE.txt`, extracted verbatim from the
`license.rtf` embedded in the installer itself. There is no published URL for this
document — unlike the v14 terms, which Microsoft hosts behind
<https://aka.ms/VCRedistLicense>, the 2012 EULA ships only inside the bundle.
`source.ps1` also copies it into the payload as `LICENSE.txt`, so the terms reach
the machine the runtime is installed on rather than only living here.

Both the x86 and x64 bundles embed a byte-identical copy — the same payload, SHA-1
`A427F89E8DC5F1784208F6755486F8B1805F67F5`, in each.

### The redistribution grant

Microsoft's REDIST list for Visual Studio 2012 names these installers explicitly:

> This is the "REDIST list" that is referenced in the "Distributable Code" section
> of the Microsoft Software License Terms for certain editions of Microsoft Visual
> Studio 2012 ("the software"). Please check the License Terms to your edition of
> the software to determine whether those License Terms reference this REDIST
> list. If you have a validly licensed copy of such software, you may copy and
> distribute the unmodified object code form of the files listed below, subject to
> the software's License Terms and to the additional terms or conditions (if any)
> that are indicated.

and under **Visual C++ Runtime Redist**:

> Subject to the license terms for the software, you may redistribute the .EXE
> files (unmodified) listed below.
>
> These files can be run as prerequisites during installation.
>
> - vcredist_x86.exe
> - vcredist_x64.exe
> - vcredist_arm.exe

<https://learn.microsoft.com/en-us/visualstudio/releases/2012/2012-redistribution-vs>

This is why the package is shaped the way it is. The grant is for **these files,
by name, unmodified**, so that is exactly what ships:

- The installers are carried byte-for-byte as Microsoft served them —
  6,554,576 bytes for x86 and 7,186,992 for x64, at `11.0.61030.0`. Nothing here
  repacks, extracts or patches them. The SHA-256 digests are
  `B924AD8062EAF4E70437C8BE50FA612162795FF0839479546CE907FFA8D6E386` (x86) and
  `681BE3E5BA9FD3DA02C09D7E565ADFA078640ED66A0D58583EFAD2C1E3CC4064` (x64), which
  match the digests in Microsoft's own winget package manifests.
- They keep their **upstream filenames**. The v14 package in this organisation
  normalises its payload to `vc_redist.<arch>.exe` for a uniform layout; this one
  deliberately does not, because the grant enumerates `vcredist_x86.exe` and
  `vcredist_x64.exe` specifically. `LANCommander.Redistributables.VisualCppV12`
  made the same call for the same reason.
- No copyright, trademark or patent notices have been altered or removed, and the
  license text travels with the binaries.

`vcredist_arm.exe` is named in the grant too and is not shipped. That is a
targeting decision, not a licensing one — ARM32 Windows RT is not a LANCommander
client target.

### The condition, and one clause that sits against it

Two things are worth stating plainly rather than leaving for someone to discover.

The grant is conditioned on **having a validly licensed copy** of Visual Studio
2012, and it does not run to every edition. Visual Studio 2012 Express for Windows
Desktop has its own, narrower REDIST list, covering the merge modules and the
loose runtime DLLs but **not** the `vcredist_*.exe` installers. The grant relied
on here is the one attached to the Ultimate, Premium and Professional editions.

Separately, the EULA embedded in the installer — the one in
`UPSTREAM-LICENSE.txt` — contains **no Distributable Code section of its own**,
and under *Scope of License* says you may not:

> publish the software for others to copy;
>
> rent, lease or lend the software;
>
> transfer the software or this agreement to any third party; or

Those two documents point in different directions. The Visual Studio license
terms are the more specific instrument here — they name these exact files for
this exact purpose, which the standalone EULA does not address at all — and that
is the basis on which the installers are bundled.

One difference from the 2013 package is worth recording, because it runs in our
favour and it would be easy to flatten the two versions together. The 2013 REDIST
list grants its files "with your program", which makes a redistributables library
a reasonable but not airtight reading. The 2012 Visual C++ section carries no such
qualifier: it says only that you may redistribute the .EXE files unmodified, and
adds that they may be run as prerequisites during installation — which is
precisely what this package does with them. The page-level preamble still
conditions everything on holding a valid license.

This is a genuinely stronger position than the v14 package in this organisation,
whose standalone terms carry no redistribution grant anywhere. It is not a
position free of tension, and saying so is more useful than implying otherwise.

### If you would rather we did not

If you are at Microsoft, or anyone else with standing here, open an issue and we
will switch this package to `Source.Mode: none` without argument. The packaging
module already supports it and `LANCommander.Redistributables.dgVoodoo2` is a
working example: the `.LCX` then ships scripts only, and the runtime is fetched
from Microsoft rather than from us.

The registry detection, architecture option, exit-code handling and update
workflow in this repository are all ours and are unaffected by that change. Only
where the bytes come from would differ.
