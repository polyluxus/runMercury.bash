# runMercury.bash

This collection of scripts replaces the startup scripts included in the original distribution of 
[Mercury 3.10](https://www.ccdc.cam.ac.uk/solutions/csd-system/components/mercury/), to be found in
```
/path/to/mercury/bin
```

I have deliberately chosen to suffix them with `.bash`, to distinguish them from the originals,
which use `.sh` or no suffix. Symbolic links with the original file names are also included.

The scripts should not break on creating a symbolic links to them anymore, i.e. creating a 
`ln -s /path/to/mercury/mercury.bash mercury` in `~/bin` (which I recommend to include in `$PATH`)
will not brake the call of the program. 
They have been checked with [`shellcheck`](https://www.shellcheck.net/) and returned no error.

Obviously, **use them on your own risk**! There is no warrenty, whatsoever.

Martin, February 2018

