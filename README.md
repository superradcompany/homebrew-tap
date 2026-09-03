# homebrew-tap

Homebrew formula for projects mantained by [Super Rad Company](https://superrad.company). 

They include:
- [microsandbox](https://github.com/superradcompany/microsandbox)

## Install

```sh
brew install superradcompany/tap/microsandbox
```

### mise

On Apple Silicon macOS, microsandbox can also be installed through mise's
Homebrew package manager:

```toml
[bootstrap.packages]
"brew:superradcompany/tap/microsandbox" = "latest"
```

The tap's mise metadata currently targets Apple Silicon macOS. Linux users
should install through Homebrew directly.

## Update

```sh
brew update
brew upgrade microsandbox
```

## Uninstall

```sh
brew uninstall microsandbox
brew untap superradcompany/tap
```
