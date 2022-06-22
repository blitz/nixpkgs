{ lib, buildPackages, fetchFromGitHub, perl, buildLinux, nixosTests, modDirVersionArg ? null, ... } @ args:

with lib;

buildLinux (args // rec {
  version = "6.3.0";
  modDirVersion = "6.3.0";

  # modDirVersion needs to be x.y.z, will automatically add .0 if needed
  #modDirVersion = if (modDirVersionArg == null) then concatStringsSep "." (take 3 (splitVersion "${version}.0")) else modDirVersionArg;

  # branchVersion needs to be x.y
  extraMeta.branch = versions.majorMinor version;

  src = fetchFromGitHub {
    owner = "Rust-for-Linux";
    repo = "linux";
    rev = "bc22545f38d74473cfef3e9fd65432733435b79f";
    hash = "sha256-+eDxZ2Evbt9F+HeqQL9tZfFHLTDsl6JTRYScRMPcvaI=";
  };

  structuredExtraConfig = with lib.kernel; {
    DEBUG_INFO_BTF = no;
    MODVERSIONS = no;
    RETPOLINE = no;

    RUST = yes;
    SAMPLES = yes;
    SAMPLES_RUST = yes;
  };

  isRust = true;

} // (args.argsOverride or { }))
