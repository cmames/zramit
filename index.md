# zramit
Zram swap with hibernate for linux system

<a href="https://github.com/cmames/zramit">https://github.com/cmames/zramit</a>

### Why?

There are dozens of zram swap scripts out there, but most of them are overly
complicated and do things that haven't been neccessary since linux 3.X or have
massive logic errors in their swap size calculations.
Other zram swap scripts don't take care of hibernate or hybrid-sleep and don't
take care of running out of RAM. Zramit do!

### Installation

download <a href="https://github.com/cmames/zramit/archive/V2.0.zip">zip</a> or 
<a href="https://github.com/cmames/zramit/archive/V2.0.tar.gz">tar.gz</a><br>
or
```
git clone https://github.com/cmames/zramit.git
```
go in the directory created
```
cd zramit
```
and install
```
./zramit.sh --install
```

### Configure

By editing
```
/etc/default/zramit.conf
```

Or with the configure assistant
```
zramit --config
```
### Status

display status with
```
zramit --status
```

or dynamic status (auto refresh every second) with
```
zramit --dstatus
```

### Hibernate, Hybrid-sleep, Suspend

Zramit assure end of zram swap before entering hibernate, and assure start at
resume from hibernate. On resume it move pages from swapfile into zram swap.

Hybrid-sleep is like hibernate to take care in case of power failure.

On suspend, zramit do nothing.

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

Run `zramctl` during use to monitor swap compression and real memory usage or run `zramit --status`

### Compatibility

This should run on pretty much any recent (4.0+? kernel) Linux system using
systemd.
