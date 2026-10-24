# Στοχευμένη αναβάθμιση body-parser

Το ενεργό Dashboard κλειδώνει το `body-parser` στην `1.20.9`, για τη διόρθωση
[CVE-2026-111181 / GHSA-27r3-jxmh-p828](https://github.com/expressjs/body-parser/security/advisories/GHSA-27r3-jxmh-p828)
(High, CVSS 7.5). Ελέγχεται και η επίλυση της εξάρτησης μέσω Express.

## Τοπική επαλήθευση

Από τον φάκελο `web_dashboard_node`:

```sh
npm ci --ignore-scripts --no-audit --no-fund
npm ls body-parser --all
node --check server.js
node --test test/body-parser-security.test.cjs
```

Τα tests δημιουργούν απομονωμένες διεργασίες σε τυχαίες θύρες loopback.
Δεν πρέπει να σταλούν τα δοκιμαστικά αιτήματα στον πραγματικό server.
Το project δεν διαθέτει διαμορφωμένο linter ή type checker.

## NickServer / Ubuntu

Μεταφέρετε το `upgrade-body-parser.sh` στον server. Οι παρακάτω εντολές εκτελούνται
εκεί, από τον φάκελο όπου αποθηκεύτηκε το script:

```sh
# Μόνο ανάγνωση, χωρίς αλλαγή αρχείων ή υπηρεσίας:
sudo bash upgrade-body-parser.sh --check

# Εγκατάσταση και σύντομη διακοπή μόνο του dashboard.service:
sudo bash upgrade-body-parser.sh --apply
```

Αν η υπηρεσία ακούει σε άλλη θύρα, προσθέστε την πραγματική διεύθυνση ως δεύτερο
όρισμα, π.χ. `--check http://127.0.0.1:3001/health` και αντίστοιχα στο `--apply`.
Η απάντηση του `/health` πρέπει να είναι `ok`.

Το script εντοπίζει τον φάκελο από το `WorkingDirectory` της υπηρεσίας και
χρησιμοποιεί τον εκτελέσιμο Node.js της ενεργής διεργασίας. Απαιτεί ενεργή υπηρεσία,
διαθέσιμο npm και αρκετό χώρο για πλήρη αντίγραφα του `node_modules`.
Δεν υποστηρίζει υπηρεσία με wrapper ως MainPID ή συνδέσμους στα αρχεία προς αλλαγή.

Πρώτα αποθηκεύει τα manifests και ολόκληρο το `node_modules` σε ιδιωτικό φάκελο
δίπλα στην εγκατάσταση. Εγκαθιστά σε ξεχωριστό φάκελο με απενεργοποιημένα lifecycle
scripts. Αν μετακινηθεί άλλη εξάρτηση, σταματά πριν αλλάξει η υπηρεσία.
Στη συνέχεια σταματά την υπηρεσία, μεταφέρει τα έτοιμα αρχεία, ξεκινά την υπηρεσία
και ελέγχει health και logs. Σε σφάλμα μετά την έναρξη της εφαρμογής επιχειρεί
αυτόματη επαναφορά, με έλεγχο health και σαφή αναφορά αν η επαναφορά αποτύχει.

Διατηρεί backup, staging και logs για έλεγχο. Το rollback επαναφέρει την προηγούμενη,
ευάλωτη έκδοση και χρειάζεται επανάληψη της συντήρησης αφού διερευνηθεί η αποτυχία.
Δεν καλύπτει διακοπή ρεύματος ή `SIGKILL` κατά τη μεταφορά αρχείων.

Για χειροκίνητη επαναφορά, ορίστε **τις ακριβείς διαδρομές που εμφάνισε το script**:

```sh
APP='/actual/dashboard/directory'
BACKUP='/actual/dashboard-body-parser-backup.XXXXXXXX'
sudo bash -s -- "$APP" "$BACKUP" <<'BASH'
set -euo pipefail
app=$(realpath -e -- "$1")
backup=$(realpath -e -- "$2")
[[ "$app" != / && "$app" == "$(realpath -e -- "$(systemctl show dashboard.service --property=WorkingDirectory --value)")" ]]
test -f "$backup/package.json"
test -f "$backup/package-lock.json"
test -d "$backup/node_modules"
systemctl stop dashboard.service
if [[ -e "$app/node_modules" ]]; then
    failed=$(mktemp -d "$(dirname -- "$app")/dashboard-failed.XXXXXXXX")
    mv -- "$app/node_modules" "$failed/"
fi
cp -a -- "$backup/package.json" "$backup/package-lock.json" "$backup/node_modules" "$app/"
systemctl start dashboard.service
curl --fail http://127.0.0.1:3000/health
BASH
```

Το script ελέγχθηκε τοπικά ως προς τη σύνταξη. Η συμπεριφορά systemd και η
επαναφορά στον NickServer απαιτούν επιβεβαίωση στο πραγματικό περιβάλλον.
Δεν αναβαθμίζει το runtime Node.js ή πακέτα Ubuntu. Το `server.js` παραμένει ίδιο.
Τα αρχεία κάτω από `docs/` είναι αγνοημένα ιστορικά αντίγραφα, όχι πηγή deployment.
Οι αλλαγές του ενεργού Dashboard πρέπει να γίνουν commit/push πριν μελλοντικό
deployment από GitHub. Το `node_modules` δεν αποθηκεύεται στο Git.
