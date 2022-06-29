function usego() {
  local version="$1"

  if [[ -n $version ]]; then
    mkdir -p $TOOLS/go
    if [[ ! -d $TOOLS/go/$version ]]; then
      curl -L -O "https://golang.org/dl/go${version}.linux-amd64.tar.gz"
      tar -xzf go${version}.linux-amd64.tar.gz
      mv go $TOOLS/go/$version
      rm go${version}.linux-amd64.tar.gz
    fi
    ln -fs $TOOLS/go/$version/bin/* $TOOL_BIN
  else
    echo 'Usage: usego <go_version>'
  fi
}
