# envybash
An attempt of reimplementing EnvyControl in a shell script

**Run at your own risk.** 

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
