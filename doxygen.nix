{ writeShellScriptBin }:
writeShellScriptBin "doxygen" ''
  # FIXME: extra layer of indirection because i forgor the short incantation for reusing a file
  # as a script
  exec bash ${./doxygen.sh}
''
