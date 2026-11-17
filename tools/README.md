# 🛠️ tools — Εργαλεία για τα README

Βοηθητικά scripts για το κεντρικό [`README.md`](../README.md) / [`README.en.md`](../README.en.md) του repository.
Τρέχουν από τη **ρίζα του repository** (`C:\BoxingGymSensorsProject`).

| Script | Τι κάνει | Πότε το τρέχω |
|---|---|---|
| [`render_diagrams.py`](./render_diagrams.py) | Μετατρέπει τα διαγράμματα `pictures/diagrams/*.mmd` σε εικόνες `.png` με σκούρο φόντο | Όταν αλλάξει κάποιο αρχείο `.mmd` |
| [`build_readme_pdf.py`](./build_readme_pdf.py) | Φτιάχνει τα `README.pdf` (ελληνικά) και `README.en.pdf` (αγγλικά) από τα αντίστοιχα `.md` | **Μετά από κάθε αλλαγή** στο `README.md` ή στο `README.en.md` |

**Απαιτήσεις:** Python 3, Google Chrome, σύνδεση στο Internet. Για τα διαγράμματα χρειάζεται και το Pillow (`pip install pillow`).

```powershell
python tools/render_diagrams.py     # 1. μόνο αν άλλαξε κάποιο .mmd
python tools/build_readme_pdf.py    # 2. πάντα, στο τέλος των αλλαγών στα README
```

> Γιατί εικόνες και όχι Mermaid μέσα στο README; Η εφαρμογή GitHub για κινητά (iOS) δεν σχεδιάζει διαγράμματα Mermaid και δείχνει τον κώδικά τους. Οι εικόνες φαίνονται παντού.

---

## ✅ Λίστα ελέγχου για νέα έκδοση της εφαρμογής (π.χ. 1.0.54 → 1.0.55)

1. Στο `box_sensors/pubspec.yaml`: `version: 1.0.55+55`.
2. Στο **`README.md` και στο `README.en.md`** άλλαξε τον αριθμό σε **2 σημεία**:
   - το badge **VERSION** στην κορυφή (`badge/version-1.0.54-...` και `alt="Version 1.0.54"`)·
   - τη γραμμή **«v1.0.54+54»** στην ενότητα **📦 Dependencies — Modules**.
3. Αν άλλαξαν εκδόσεις πακέτων, ενημέρωσε και τους πίνακες των Dependencies (και τα μικρά badges πάνω από αυτούς).
4. Ξαναφτιάξε τα PDF: `python tools/build_readme_pdf.py`.
5. Έλεγξε το αποτέλεσμα (προεπισκόπηση στο VS Code / PDF) και μετά κάνε commit & push.

---

## 📝 Κανόνες για τα README

- Το ελληνικό και το αγγλικό README έχουν **ακριβώς την ίδια δομή**: κάθε αλλαγή γίνεται και στα δύο.
- Τα αρχεία `README_backup.md` / `README.en_backup.md` είναι μόνο τοπικά (δεν ανεβαίνουν, βλ. `.gitignore`).
- Μετά από push, το GitHub μπορεί να δείχνει για ~5 λεπτά παλιές εικόνες (cache). Λύση: αναμονή και **Ctrl+F5**.
