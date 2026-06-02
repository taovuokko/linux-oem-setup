# Arkkitehtuuri

OEM-setup on jaettu tavalliseen Qt/QML-GUI:hin ja kahteen pieneen rootina
ajettavaan skriptiin.

## Osat

- `/usr/bin/oem-setup-gui`: first boot -wizard setup-käyttäjän sessiossa.
- `/usr/libexec/oem-setup/oem-apply.sh`: pkexecillä ajettava käyttöönotto.
- `/usr/libexec/oem-setup/oem-cleanup.sh`: systemd-palvelun ajama loppusiivous.
- `/etc/oem-setup/oem-setup.conf`: installerin kirjoittama ajonaikainen konffi.
- `/usr/lib/systemd/system/oem-cleanup.service`: retryttävä cleanup-unit.

GUI ei tee root-toimintoja suoraan. Se kerää nimen, käyttäjätunnuksen, localen
ja salasanan, validoi ne aikaisin ja kutsuu `oem-apply.sh`:ta pkexecin kautta.
Skripti validoi tiedot uudelleen ennen kuin koskee käyttäjiin tai järjestelmän
konffeihin.

Cleanup-palvelu ajetaan seuraavassa bootissa ennen graafista ympäristöä. Se
poistaa ensin autologinin ja vasta sitten setup-käyttäjän, jotta kone ei jää
kirjautumaan poistettuun käyttäjään.

## Paketointi

Release-AppImage rakennetaan GitHub Actionsissa linuxdeploylla. Nix-shell on
kehitystä varten.
