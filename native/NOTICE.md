# Monitor Control Native — 2.1.1

This module is a modified version of **Per-monitor brightness in Quick Settings
2.1**, originally authored by **bardelyne**. The original author and GNU GPL-3.0
license metadata are preserved in the source.

Upstream source, pinned revision:
https://github.com/ramensoftware/windhawk-mods/blob/325e75600e4ed1367e8d118969097e64fbc3ef72/mods/per-monitor-brightness.wh.cpp

Author's project:
https://github.com/bardelyne/per-monitor-brightness

Original source attribution also credits m417z's **Windows 11 Notification Center
Styler** for the approach used to execute work on the shell's XAML thread.

Local modifications, 2026-11-11:

- Separate module ID `monitor-control-native` and version `2.1.1`.
- Russian visible labels, settings and module documentation.
- Brightness controls above the native Windows sliders by default.
- Explicit physical-monitor handle ownership, including successful zero-valued
  handles; cleanup on discovery failures and after a worker exits unexpectedly.
- Conservative one-to-one physical-monitor identity mapping: ambiguous cloned
  display groups are left uncontrollable rather than controlling an uncertain
  physical target.
- Widened raw brightness arithmetic to avoid DWORD overflow; reject invalid
  monitor ranges and WMI percentages outside 0..100.

This remains a brightness-only module: external control uses VCP `0x10`; there
are no contrast, input, power, or capabilities-string queries. Initial discovery
only reads brightness. Following changes to internal-panel brightness is off by
default and remains an explicit setting.

The accompanying `LICENSE` is the GNU General Public License, version 3.
Distributing a compiled or modified version requires complying with that license,
including providing the corresponding source and retaining applicable notices.

Compatibility is dependent on the Windows shell build. The original author
tested version 2.1 on Windows 11 25H2 (build 26200). This adaptation was confirmed
working by the user with AQW34H3, NVIDIA RTX 5070 and Windows 11 build 26300.9711:
the slider appeared in Quick Settings and changed the monitor's brightness.
Other hardware and Windows builds still require validation.
