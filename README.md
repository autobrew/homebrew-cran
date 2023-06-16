# The homebrew-cran tap

A Homebrew tap with some formulae for building CRAN packages.

```
brew tap autobrew/cran
brew install apache-arrow-static
```

# CI setup

~Based on: https://github.com/dawidd6/homebrew-tap~ The workflows are based on those from `brew tap-new`.

# Bundles

Binaries built with this tap are used to create [bundles](https://github.com/autobrew/bundler). A bundle is an archive containing the static library plus all dependencies, for [easy downloading by R packages](https://github.com/autobrew/scripts).
