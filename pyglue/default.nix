{ pkgs
, lib
, buildPythonPackage
, setuptools
, requests
, ...
}:

pkgs.python3Packages.buildPythonPackage rec {
  pname = "screensystem";
  version = "0.0.1";
  format = "setuptools";

  nativeBuildInputs = [ setuptools ];
  propagatedBuildInputs = [ requests ];
  doCheck = false;
  src = ./.;

  meta = with lib; {
    homepage = "http://zrave.club";
    description = "Controls kiosk systems for furcons";
  };
}
