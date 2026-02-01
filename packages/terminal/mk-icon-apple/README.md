# mkiconapple
  Creates an apple icon (icns) based on a list of images with different
    sizes.

## Nix commands

### Add to the user profile

```bash
nix add github:juanma151/mk-icon-apple
```

### Add to a specific profile

```bash
nix add --profile "/route/to/profile" github:juanma151/mk-icon-apple
```

### Run

```bash
nix run github:juanma151/mk-icon-apple -- ARGS
```

## Examples 

### Adds the images manually

```bash
mkiconapple --out OUTPATH --workdir WD \
  --sizepath "S1:PATH1" --sizepath "S2:PATH2"
```

```bash
mkiconapple --out /my/out/icon --workdir /my/source/images \
  --sizepath "32:32x32/icon.png" --sizepath "1024:1024x1024/icon.png"
```

### Adds the images using a regex to get the size

The regex is really a valid ZSH glob regex.

With the regex it's not necessary to indicate the size on each path (as opposed to --sizepath "SIZE:PATH")

```bash
mkiconapple --out OUTPATH --workdir WD \
  --regex REGEX --group 1 \
  --globpath GLOB1 --globpath GLOB2 \
  --path PATH1 --path PATH2
```

```bash
mkiconapple --out /my/out/icon --workdir /my/source/images \
  --regex '([0-9]##)x' --group 1 \
  --globpath '*/icon.png' --path '1024x1024/icon.png'
```


## DEFAULTS:

- `workdir`
  - is the current folder by default
- `group`
  - is 1 by default


## OPTIONS

### Help
`-h // --help`

> Shows this help.

### Out Path
`-o / --out PATH`

> Output path (file should not have extension or have .icns)

### Working Directory
`-w // --wd // --workdir PATH`

>Base directory for the input paths (globdirs, dirs and sizedirs).
By default is the current dir.

### Adding paths directly
`-s // --spath // --sizepath PATH`

> Adds a sizepath. A sizepath has the format "SIZE:PATH". Not valid with regex.

> EX.: "1024:/path/to/my/img.png"

### Adding paths with RegEx
`-r / --rg / --regex REGEX`

>Regular expresion to get the sizes from the dirs.

>If the regular expression doesn't have '(#b)' (capture groups) that will be prefixed. If the regular expression doesn't end in '*', that will be suffixed.

>If regex is set, the input files should be added with --globdir or --dir.

>If regex is set and the matching group that contains the size is different than 1, --group should be used.

`-g // --grp // --group NUMBER`

>Match group that contains the size in the regex.

`-g // --gpath // --globpath PATH`

>Adds a glob input path (will use file generation). Only valid with regex.

`-p // --path // --plainpath PATH`

> Adds a input path. Only valid with regex.
