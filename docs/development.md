# Kehitys

Projektia kehitetään repo-kohtaisessa Nix-shellissä.

```bash
nix develop
just build
just run
just check
```

Älä nojaa hostin C++-headereihin tai kirjastoihin. Lisää C++/Qt-riippuvuudet
`flake.nix`:iin ja linkitä ne CMakeen.

GUI:ssa on mock-tila paikallista ajamista varten. Tuotannon root-toiminnot ovat
skripteissä `data/scripts/oem-apply.sh` ja `data/scripts/oem-cleanup.sh`, eivät
QML:ssä tai GUI-controllerissa.

Koodityyli ja tarkemmat säännöt ovat tiedostossa `docs/coding-style.md`.
