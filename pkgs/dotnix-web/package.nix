{
  writeShellApplication,
  curl,
  jq,
  htmlq,
  w3m,
  gawk,
  coreutils,
}:

writeShellApplication {
  name = "dotnix-web";
  runtimeInputs = [
    curl
    jq
    htmlq
    w3m
    gawk
    coreutils
  ];
  text = builtins.readFile ./dotnix-web.sh;
  meta.description = "Web search and fetch for shell-only coding agents";
}
