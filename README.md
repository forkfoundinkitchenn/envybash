# envybash
An attempt of reimplementing EnvyControl in Bash

## NOTES
1. This project is currently in a pre-alpha phase and lacks a lot of features that EnvyControl already has.
2. At the moment, only Arch, Void, and Fedora are supported. I'm hoping to add support for derivatives and more distros soon.
3. I have hardly looked at EnvyControl's source code, so this is mostly my interpretation of how it works.
4. This is not intended to be a drop-in replacement for EnvyControl nor similar tools, I just wrote this for my own convenience and decided to make it a bigger thing.. **Use at your own risk!!**
5. When running the automatic installer as a normal user, it won't work out of the box when running ``sudo envybash`` because it's unable to read your PATH.

## INSTALLATION METHODS
### Manual
1. Clone the github repository
```
git clone https://github.com/forkfoundinkitchenn/envybash.git
```
2. ``cd`` into the project folder and run it directly
```
sudo ./main.sh -s integrated
```
3. Or symlink it to a directory in your PATH
```
ln -sf /directory/to/envybash/main.sh ~/.local/bin/envybash
```
### Automatic
1. Run this command (omit ``sudo`` to install for your user, not recommended though)
```
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/forkfoundinkitchenn/envybash/refs/heads/main/install.sh)"
```

## USAGE
* Switch modes
```
sudo envybash -s integrated
```
```
sudo envybash -s hybrid
```
* Query mode
```
envybash -q
```
* Verbose
```
sudo envybash -v -s integrated
```

## ROADMAP TO ALPHA
* Add support for derivatives + extra distros
* Manage X11 configs
* Add NVIDIA mode
