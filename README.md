# zramit
Zram swap and more for linux

### Why?

There are dozens of zram swap scripts out there, but most of them are overly
complicated and do things that haven't been neccessary since linux 3.X or have
massive logic errors in their swap size calculations. This script is simple and
reliable, modern and easy to configure.

### Installation

```
cd zramit
sudo ./install.sh
```

### Usage

zramit.service will be started automatically after installation and during
each subsequent boot. The default allocation creates a zram device that should
use around half of physical memory when completely full.

The default configuration using lz4 should work well for most people. lzo may
provide slightly better RAM utilization at a cost of slightly more expensive
decompression. zstd should provide better compression than lz* and still be
moderately fast on most machines but slow on old machines. On very modern 
kernels the best overall choice is probably lzo-rle.

Edit `/etc/default/zramit.conf` if you'd like to change compression algorithms 
or swap allocation and then restart zramit with 
`systemctl restart zramit.service`.

Run `zramctl` during use to monitor swap compression and real memory usage.

### Compatibility

This should run on pretty much any recent (4.0+? kernel) Linux system using
systemd.
