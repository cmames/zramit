# zramit
[![GitHub license](https://img.shields.io/github/license/cmames/zramit?style=plastic)](https://github.com/cmames/zramit/blob/main/LICENSE)
![GitHub code size in bytes](https://img.shields.io/github/languages/code-size/cmames/zramit?style=plastic)
![GitHub release (latest by date)](https://img.shields.io/github/v/release/cmames/zramit?style=plastic)
![GitHub last commit](https://img.shields.io/github/last-commit/cmames/zramit?style=plastic)
![Code Grade](https://www.code-inspector.com/project/18173/score/svg)
[![Code Grade](https://www.code-inspector.com/project/18173/status/svg)](https://www.code-inspector.com/public/project/18173/zramit/dashboard)

Zram swap with hibernate for linux system

---
### Why?

There are dozens of zram swap scripts out there, but most of them are overly
complicated and do things that haven't been neccessary since linux 3.X or have
massive logic errors in their swap size calculations.
Other zram swap scripts don't take care of hibernate or hybrid-sleep and don't
take care of running out of RAM. Zramit do!

---
### Installation

Download and unzip the zip or tar.gz from lastest release
or
```
git clone https://github.com/cmames/zramit.git
```
and
```
cd zramit
./zramit.sh --install
```
You can delete the zramit directory after install.

---
### Configure

By editing
```
/etc/default/zramit.conf
```

Or with the configure assistant
```
zramit --config
```
---
### Status

display status with
```
zramit --status
```

or dynamic status (auto refresh every second) with
```
zramit --dstatus
```

---
### Hibernate, Hybrid-sleep, Suspend

Zramit assure end of zram swap before entering hibernate, and assure start at
resume from hibernate. On resume it move pages from swapfile into zram swap.

Hybrid-sleep is like hibernate to take care in case of power failure.

On suspend, zramit do nothing.

---
### Usage

Zramit.service will be started automatically after installation and during
each subsequent boot. The default allocation creates a zram device that should
use around half of physical memory when completely full.

The default configuration using lz4 should work well for most people. lzo may
provide slightly better RAM utilization at a cost of slightly more expensive
decompression. zstd should provide better compression than lz* and still be
moderately fast on most machines but slow on old machines. On very modern
kernels the best overall choice is probably lzo-rle.

Edit `/etc/default/zramit.conf` if you'd like to change compression algorithms
or swap allocation and then restart zramit with

`systemctl restart zramit.service`

or

`zramit --restart`

Run `zramctl` to monitor swap compression and real memory usage or run

`zramit --status`

---
### Compatibility

This should run on pretty much any recent (4.0+? kernel) Linux system using
systemd.
