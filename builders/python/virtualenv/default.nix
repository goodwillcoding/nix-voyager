{ pkgs , fetchurl, lib , builders }:
let
   inherit (builtins) removeAttrs;
   inherit (lib) lists;
   inherit (lib.attrsets) attrNames;
   ##############################
   inherit (builders) mkBuild;
in
{ mainPackageName
, src
, installDepsFromRequires ? ""
, systemPython ? "/usr/bin/python"
, virtualEnvSrc ? null
, preLoadedPythonDeps ? []
, exposedCmds ? []
, useBinaryWheels ? false
, namePrefix ? null
, logExecution ? false
# define this parameter to create the venv on this path,
# useful to build the venv inside a docker container
, storePath ? ""
# this attribute is for small experiments...
# don't rely a lot on it
, extraDirectAttrs ? {}
, ...} @ args:
let
  defaultVirtualEnvSrc = fetchurl {
     url = "https://pypi.io/packages/source/v/virtualenv/virtualenv-16.2.0.tar.gz";
     sha256 = "1ka0rlwhcsqkv995jr1xfglhj9d94avbwippxszx52xilwqnhwzs";
   };

  virtualEnvTar = (
    if virtualEnvSrc != null
      then  virtualEnvSrc
    else  defaultVirtualEnvSrc
  );

  coreAttributes = {
    inherit logExecution;
    namePrefix = args.namePrefix or null;
    allowedSystemCmds = [
      "/usr/bin/ldd"
      "/usr/bin/gcc"
    ];
    buildInputs = with pkgs; [
      coreutils lsb-release
      gnutar gzip gnugrep
      file findutils
    ];
    scriptPath = ./python-venv-builder.sh;
    directAttrs = ({
      preLoadedPythonDeps = lists.flatten (map (d: [ d.name d.src ]) preLoadedPythonDeps);
      inherit mainPackageName src systemPython virtualEnvSrc
              exposedCmds useBinaryWheels virtualEnvTar
              installDepsFromRequires storePath;
    } // extraDirectAttrs) ;
  };
  mkBuildArgs = removeAttrs args ((attrNames coreAttributes.directAttrs) ++ [ "extraDirectAttrs"]);
in
   mkBuild (coreAttributes // mkBuildArgs)
