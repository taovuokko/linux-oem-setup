# OEM Setup

Pieni OEM‑käyttöönottoavustin distroille, joista puuttuu valmis OEM‑asennus.  

Ideana on, että käyttäjä luo ensimmäisellä bootilla oman tilinsä ja kielen, ilman ylimääräistä säätöä.

## Seuraavan sukupolven versio

Repoon on aloitettu C++/Qt/QML-pohjainen tuotetason versio nykyisen
bash/zenity-toteutuksen rinnalle.

Nykyinen kehitysrakenne:

* `src/gui` — Qt/QML wizard mock-backendillä
* `src/helper` — tuleva root-helper, nyt validointi- ja protokollastubina
* `src/common` — jaettu syötevalidointi
* `data` — desktop-, polkit-, systemd- ja oletuskonfiguraatiot
* `docs` — arkkitehtuuri-, koodaustyyli-, tietoturva- ja testausmuistiot

Kehitys tapahtuu Nix-kehitysympäristössä:

```bash
nix develop
just build
just run
just check
```

Ensimmäinen C++-milestone keskittyy GUI/UX-polkuun. Root-toiminnot portataan
myöhemmin helperiin nykyisestä `usr/local/sbin/oem-setup-apply.sh`-logiikasta.

## Käyttö
1. Kopioi `oem-setup` asennettuun järjestelmään.
2. Siirry kansioon:

   ```bash
   cd oem-setup
   ```
3. Aja asennus:

   ```bash
   sudo ./install.sh
   ```
4. Käynnistä kone uudelleen.

Ensimmäisellä bootilla:

* `setup`-käyttäjä kirjautuu automaattisesti
* käyttöönottoavustin käynnistyy
* käyttäjä luo oman tilinsä
* kone käynnistyy uudelleen
* `setup`-tili ja OEM-tiedostot poistuvat automaattisesti

## Tuetut distrot
- Fedora‑pohjaiset (Fedora, Nobara tms.)
- Arch‑pohjaiset (EndeavourOS, CachyOS, Manjaro, Garuda)
- Muut → generinen polku (Debian/Ubuntu‑tyyliset)


Jos puuttuvia paketteja löytyy, asennus yrittää asentaa ne ja kertoo lopuksi mikä jäi puuttumaan.
