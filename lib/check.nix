{ stdenv, lib, haskellLib, srcOnly }:
drv:

let
  component = drv.config;

# This derivation can be used to execute test component.
# The $out of the derivation is a file containing the resulting
# stdout output.
in stdenv.mkDerivation ({
  name = (drv.name + "-check");

  # Useing `srcOnly` (rather than getting the `src` via a `drv.passthru`)
  # should correctly apply the patches from `drv` (if any).
  src = srcOnly drv;

  passthru = {
    inherit (drv) identifier config configFiles executableToolDepends cleanSrc env;
  };

  inherit (drv) meta LANG LC_ALL;

  inherit (component) doCheck doCrossCheck;

  phases = ["buildPhase" "checkPhase"];

  # If doCheck or doCrossCheck are false we may still build this
  # component and we want it to quietly succeed.
  buildPhase = ''
    touch $out
  '';

  checkPhase = ''
    runHook preCheck

    ${toString component.testWrapper} ${drv}/${drv.installedExe} ${lib.concatStringsSep " " component.testFlags} | tee $out

    runHook postCheck
  '';
} // haskellLib.optionalHooks {
  inherit (component) preCheck postCheck;
})
