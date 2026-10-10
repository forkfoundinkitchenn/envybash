# envybash
An attempt of reimplementing EnvyControl in a shell script

**Probably unstable. Run at your own risk.**

## NOTES
1. This project is currently in a pre-alpha phase and lacks a lot of features that EnvyControl already has. 
2. Theoretically.. Arch, Fedora, and Debian/Ubuntu should work.. That's all I plan to support for the time being.
3. I have hardly looked at EnvyControl's source code, so this is mostly my interpretation of how it works.
4. I mainly wrote this for my own convenience because.. EnvyControl would just not work on my Void Linux system. Now, I could've forked it and fixed the issue I was having but I'm not very familiar with Python so I made a quick wrapper script trying to emulate what EnvyControl did and then it spiraled into whatever it's becoming here..
5. If ``sudo`` ever returns that it can't find the command ``envybash``, this is most likely because you have it installed locally. There are a few workarounds to this, but you may just symlink ``main.sh`` to somewhere like ``/usr/bin`` instead.

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
sudo ln -sf /directory/to/envybash/main.sh /usr/bin/envybash
```
### Automatic
1. Run this command (alternatively, omit ``sudo`` to install for your user)
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

## ALPHA RELEASE
* NVIDIA-only mode
* Derivative support
