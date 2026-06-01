# OEM Setup

Pieni OEM‑käyttöönottoavustin distroille, joista puuttuu valmis OEM‑asennus.  

Ideana on, että käyttäjä luo ensimmäisellä bootilla oman tilinsä ja kielen, ilman ylimääräistä säätöä.

## Rakenne

Projektin nykyinen toteutus on C++/Qt/QML-pohjainen:

* `src/gui` — Qt/QML wizard
* `src/helper` — root-helper järjestelmämuutoksia varten
* `src/common` — jaettu syötevalidointi
* `data` — desktop-, polkit-, systemd- ja oletuskonfiguraatiot
* `docs` — arkkitehtuuri-, koodaustyyli-, tietoturva- ja testausmuistiot

## Kehitys

Kehitys tapahtuu Nix-kehitysympäristössä:

```bash
nix develop
just build
just run
just check
```

## Käyttö

Asennus käyttää CMake-installointia:

```bash
cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build build
sudo cmake --install build
```

Ensimmäisellä bootilla:

* `setup`-käyttäjä kirjautuu automaattisesti
* käyttöönottoavustin käynnistyy
* käyttäjä luo oman tilinsä
* kone käynnistyy uudelleen
* `setup`-tili ja OEM-tiedostot poistuvat automaattisesti
