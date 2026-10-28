final: _prev: {
  dotnix-web = final.callPackage ./dotnix-web/package.nix { };
  rtk = final.callPackage ./rtk/package.nix { };
}
