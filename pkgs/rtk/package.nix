{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:

rustPlatform.buildRustPackage {
  pname = "rtk";
  version = "0.42.4";

  src = fetchFromGitHub {
    owner = "rtk-ai";
    repo = "rtk";
    rev = "af81b08175af063c8b631979959d80c9007d089f";
    hash = "sha256-4JZmyssNQ/tsOKLTZCBtzLDsXj0Um9fXiETcpkJJJE8=";
  };

  cargoLock.lockFile = ./Cargo.lock;

  # tests require git repos and network access
  doCheck = false;

  meta = {
    description = "CLI proxy that reduces LLM token consumption by filtering command outputs";
    homepage = "https://github.com/rtk-ai/rtk";
    license = lib.licenses.asl20;
    mainProgram = "rtk";
  };
}
