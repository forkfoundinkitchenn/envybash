# envybash
An attempt of reimplementing EnvyControl in Bash

## NOTES
1. This project is currently in a pre-alpha phase and WILL lack features, like the NVIDIA mode and RTD3 power management.
2. At the moment, only Arch, Void, and Fedora are supported. I'm currently working on adding support for more distros and derivatives.
3. I have hardly looked at EnvyControl's source code, so most of the code is my interpretation of how it works.
4. This is not intended to be a drop-in replacement for EnvyControl nor similar tools, I just wrote this for my own convenience and decided to make it a bigger thing.. **Use at your own risk!!**

## INSTALLATION METHODS
### Manual
1. Clone the github repository
```
git clone https://github.com/forkfoundinkitchenn/envybash.git
```
2. ``cd`` into the project folder and run it directly
```
./main.sh -s integrated
```
3. Or symlink it to a directory in your PATH
```
ln -sf /directory/to/envybash/main.sh ~/.local/bin/envybash
```
### Automatic
1. Run this command (needs root permissions because it does a system-wide install for now)
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
sudo envybash -vs integrated
```
* Dry run
```
envybash -ds integrated
```
