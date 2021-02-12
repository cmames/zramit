# zramit
[![GitHub license](https://img.shields.io/github/license/cmames/zramit)](https://github.com/cmames/zramit/blob/main/LICENSE)
![GitHub last commit](https://img.shields.io/github/last-commit/cmames/zramit)

![GitHub top language](https://img.shields.io/github/languages/top/cmames/zramit)
![GitHub code size in bytes](https://img.shields.io/github/languages/code-size/cmames/zramit)
![GitHub release (latest by date)](https://img.shields.io/github/v/release/cmames/zramit)

![Code Grade](https://www.code-inspector.com/project/18173/score/svg)
![Code Grade](https://www.code-inspector.com/project/18173/status/svg)


:uk: Zram swap with hibernate for linux system 
> :fr: Zram swap avec prise en charge de l'hibernation pour linux

<a href="https://github.com/cmames/zramit">https://github.com/cmames/zramit</a>

---
### Why? 

There are dozens of zram swap scripts out there, but most of them are overly
complicated and do things that haven't been neccessary since linux 3.X or have
massive logic errors in their swap size calculations.
Other zram swap scripts don't take care of hibernate or hybrid-sleep and don't
take care of running out of RAM. Zramit do!

> ### Pourquoi?
>
> Il existe des dizaines de scripts de swap zram, mais la plupart sont trop
> compliqués et font des choses non pas nécessaires depuis linux 3.X ou ont
> des erreurs logiques massives dans leurs calculs de taille de swap.
> Les autres scripts de swap zram ne prennent pas en charge l'hibernation ou
> la veille hybride et ne veillent pas à protéger de la pénurie de RAM.
> Zramit le fais!

---
### Installation

Download and unzip the zip or tar.gz from [latest zramit release](https://github.com/cmames/zramit/releases/latest)

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
You can delete the zramit directory after install.

> ### Installation
>
> Téléchargez et décompressez le zip ou le tar.gz depuis [dernière zramit release](https://github.com/cmames/zramit/releases/latest)
>
> ou
> ```
> git clone https://github.com/cmames/zramit.git
> ```
> placez vous dans le répertoire créé
> ```
> cd zramit
> ```
> et installez
> ```
> ./zramit.sh --install
> ```
> Vous pouvez supprimer le répertoire après l'installation

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
> ### Configuration
>
> En modifiant
> ```
> /etc/default/zramit.conf
> ```
>
> Ou en utilisant l'assistant configuration
> ```
> zramit --config
> ```

---
### Status

Display status with
```
zramit --status
```

or dynamic status (auto refresh every second) with
```
zramit --dstatus
```

> ### Status
>
> Afficher le status avec
> ```
> zramit --status
> ```
>
> ou le status dynamique (rafraichi toutes les secondes) avec
> ```
> zramit --dstatus
> ```

---
### Hibernate, Hybrid-sleep, Suspend

Zramit assure end of zram swap before entering hibernate, and assure start at
resume from hibernate.

Hybrid-sleep is like hibernate to take care in case of power failure.

On suspend, zramit do nothing.

> ### Hibernation, Veille hybride, Veille
> 
> Zramit s'assure d'arréter le swap en zram avant d'entrer en hibernation, et
> s'assure de le relancer au retour de l'hibernation.
>
> La veille hybride est comme l'hibernation pour assurer le bon fonctionnement
> en cas de coupure d'alimentation.
>
> Dans la cas de la veille simple, zramit n'a rien besoin de faire de plus.

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

Run `zramctl` during use to monitor swap compression and real memory usage
or run `zramit --status`

You can enable or disable zramit

to disable zramit without uninstalling

`zramit --disable`

to enable zramit after disable

`zramit --enable`

For more details read the man pages

`man zramit`

> ### Utilisation
>
> Zramit.service sera lancé automatiquement après l'installation et à chaque
> démarrage ultérieur. L'installation par défaut crée un périphérique zram qui 
> doit utiliser environ la moitié de la mémoire physique lorsqu'elle est 
> complètement pleine.
>
> La configuration par défaut utilisant lz4 devrait bien fonctionner pour la 
> plupart des gens. lzo peut fournir une utilisation légèrement meilleure de la 
> RAM avec un temps légèrement plus important de décompression. zstd devrait 
> fournir une meilleure compression que lz* tout en restant modérément rapide 
> sur la plupart des machines mais lent sur les anciennes machines. Sur un noyau
> très moderne, le meilleur choix global est probablement lzo-rle.
>
> Editez `/etc/default/zramit.conf` si vous voulez changer l'algorithme de 
> compression ou l'allocation mémoire puis relancez zramit avec
> 
> `systemctl restart zramit.service`
>
> ou
>
> `zramit --restart`
>
> Lancez `zramctl` pendant le fonctionnement pour surveiller la compression du 
> swap et l'utilisation de la mémoire ou lancez `zramit --status`
>
> Vous pouvez activer ou désactiver zramit
>
> pour désactiver zramit sans désinstaller
>
> `zramit --disable`
>
> pour activer zramit après une désactivation
>
> `zramit --enable`
>
> Pour plus de détail lisez le manuel
> 
> `man zramit`
>

---
### Compatibility

This should run on pretty much any recent (4.0+? kernel) Linux system using
systemd.

> ### Compatibilité
>
> Il doit tourner sur les plus récents (kernel 4.0+?) systèmes linux utilisant
> systemd
