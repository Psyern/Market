# 🏪 DayZ Expansion Market – Price Converter

PowerShell Drag & Drop Tool zur automatischen Preisanpassung von DayZ Expansion Market JSON-Dateien mittels Power-Law-Formel.

---

## 🚀 Schnellstart (Drag & Drop)

```
1.  Windows PowerShell öffnen
2.  Die Datei  ps1\PriceConverter.ps1  ins Fenster ziehen
3.  Leertaste drücken
4.  Eine .json Datei  ODER  einen ganzen Market-Ordner reinziehen
5.  Enter drücken – fertig!
```

> ✅ Originale werden **nicht** verändert – Ergebnis landet im Unterordner **`NewMarket/`** neben den Originaldateien.

### Beispiel

```
PS> & "C:\Market\ps1\PriceConverter.ps1" "C:\Server\mpmissions\Market"

  ============================================
   DayZ Market Price Converter
  ============================================
  Ordner:   C:\Server\mpmissions\Market
  Dateien:  131
  Formel:   NeuerPreis = 0.976425 * AlterPreis ^ 0.551901
  Ausgabe:  C:\Server\mpmissions\Market\NewMarket
  ============================================

  [OK]  Cars.json  (6 / 6 Items)
  [OK]  Assault_Rifles.json  (11 / 11 Items)
  ...

  ============================================
   ZUSAMMENFASSUNG
  ============================================
  Dateien verarbeitet:  131
  Dateien geaendert:    130
  Items gesamt:         2563
  Items geaendert:      2559
  ============================================
```

---

## 📁 Projektstruktur

```
Market/
├── *.json                  # Aktuelle Market-Konfigurationsdateien
├── BACKUP/                 # Original-Backup aller JSON-Dateien (vor Anpassung)
├── ps1/                    # PowerShell-Tools
│   ├── PriceConverter.ps1  # ⭐ Haupttool: Drag & Drop Preiskonverter
│   ├── compare_prices.ps1  # Preise zwischen zwei Ordnern vergleichen
│   └── analyze.ps1         # Regressions-Analyse der Preisdaten
└── README.md
```

## 📄 JSON-Dateiformat

Jede `.json`-Datei entspricht einer Market-Kategorie (z.B. `Cars.json`, `Assault_Rifles.json`, `Food.json`) und enthält folgende Struktur:

```json
{
  "m_Version": 12,
  "DisplayName": "#STR_EXPANSION_MARKET_CATEGORY_CARS",
  "Icon": "Deliver",
  "Color": "FBFCFEFF",
  "IsExchange": 0,
  "InitStockPercent": 75.0,
  "Items": [
    {
      "ClassName": "OffroadHatchback",
      "MaxPriceThreshold": 3498,
      "MinPriceThreshold": 3199,
      "SellPricePercent": -1,
      "MaxStockThreshold": 15,
      "MinStockThreshold": 5,
      "QuantityPercent": -1,
      "SpawnAttachments": []
    }
  ]
}
```

### Preisrelevante Felder

| Feld | Beschreibung |
|---|---|
| `MaxPriceThreshold` | Höchstpreis – wenn Lager leer ist |
| `MinPriceThreshold` | Tiefstpreis – wenn Lager voll ist |
| `SellPricePercent` | Verkaufspreis-Prozentsatz (-1 = Standard) |

---

## 🧮 Die Preisformel

Die Preise wurden mit einer **Power-Law-Funktion** angepasst:

$$\text{NeuerPreis} = \text{round}\left( A \times \text{AlterPreis}^{B} \right)$$

### Standard-Parameter

| Parameter | Wert | Beschreibung |
|---|---|---|
| **A** | `0.976425` | Koeffizient (Skalierungsfaktor) |
| **B** | `0.551901` | Exponent (Kompressionsstärke) |
| **R²** | `0.9974` | Bestimmtheitsmaß (99.74% Genauigkeit) |

### Referenztabelle

| Alter Preis | Neuer Preis | Reduktion |
|---:|---:|---:|
| 5 | 2 | 60% |
| 10 | 3 | 70% |
| 50 | 8 | 84% |
| 100 | 12 | 88% |
| 500 | 30 | 94% |
| 1.000 | 44 | 95,6% |
| 5.000 | 107 | 97,9% |
| 10.000 | 157 | 98,4% |
| 50.000 | 383 | 99,2% |
| 100.000 | 561 | 99,4% |
| 500.000 | 1.364 | 99,7% |
| 1.000.000 | 2.000 | 99,8% |
| 5.000.000 | 4.862 | 99,9% |
| 10.000.000 | 7.128 | 99,9% |
| 50.000.000 | 17.326 | ~100% |
| 100.000.000 | 25.401 | ~100% |
| 500.000.000 | 61.746 | ~100% |

### Exponent-Guide (Parameter B)

Über den Exponenten **B** steuerst du, wie aggressiv die Preiskompression wirkt:

| B-Wert | Wirkung | Beispiel (Alter Preis 1.000.000) |
|---|---|---|
| `0.45` | Sehr aggressiv | → 871 |
| **`0.55`** | **Aktuelle Einstellung** | **→ 2.000** |
| `0.65` | Moderat | → 4.786 |
| `0.75` | Sanft | → 11.455 |
| `0.85` | Leicht | → 27.426 |
| `1.00` | Keine Änderung | → 1.000.000 |

---

## ⭐ PriceConverter.ps1 – Haupttool

PowerShell Drag & Drop Script zur automatischen Preisanpassung aller Market-JSON-Dateien.

### Voraussetzungen

- Windows PowerShell 5.1+ oder PowerShell 7+
- DayZ Expansion Market JSON-Dateien im Standard-Format

### Verwendung (Drag & Drop)

| Schritt | Aktion |
|---|---|
| 1 | **PowerShell öffnen** (Windows-Taste → „PowerShell" → Enter) |
| 2 | `ps1\PriceConverter.ps1` **ins Fenster ziehen** |
| 3 | **Leertaste** drücken |
| 4 | **JSON-Datei** oder **Market-Ordner** reinziehen |
| 5 | **Enter** drücken |

Die konvertierten Dateien landen automatisch im Unterordner **`NewMarket/`** neben den Originalen. Originale bleiben unverändert.

#### Einzelne Datei konvertieren

```powershell
.\ps1\PriceConverter.ps1 "C:\pfad\zu\Cars.json"
# → Ergebnis: C:\pfad\zu\NewMarket\Cars.json
```

#### Ganzen Ordner konvertieren

```powershell
.\ps1\PriceConverter.ps1 "C:\pfad\zu\Market"
# → Ergebnis: C:\pfad\zu\Market\NewMarket\*.json
```

#### Dry-Run (nur Vorschau, keine Änderungen)

```powershell
.\ps1\PriceConverter.ps1 "C:\pfad\zu\Market" -DryRun
```

#### Eigene Formel-Parameter

```powershell
# Weniger aggressiv (B=0.65)
.\ps1\PriceConverter.ps1 "C:\pfad\zu\Market" -B 0.65

# Viel aggressiver (B=0.45)
.\ps1\PriceConverter.ps1 "C:\pfad\zu\Market" -B 0.45
```

#### Nur Hilfe / Referenztabelle anzeigen

```powershell
.\ps1\PriceConverter.ps1
```

### Alle Parameter

| Parameter | Typ | Standard | Beschreibung |
|---|---|---|---|
| *(1. Argument)* | String | – | Pfad zur JSON-Datei oder zum Ordner (Drag & Drop) |
| `-A` | Double | `0.976425` | Koeffizient A der Formel |
| `-B` | Double | `0.551901` | Exponent B der Formel |
| `-DryRun` | Switch | `false` | Nur anzeigen, nichts ändern |

---

## 🔍 Weitere Tools

### compare_prices.ps1

Vergleicht Preise zwischen dem aktuellen Market-Ordner und dem BACKUP-Ordner. Erzeugt einen vollständigen Bericht aller Unterschiede.

```powershell
.\ps1\compare_prices.ps1
```

**Ausgabe:** `price_comparison_results.txt` mit allen Preisunterschieden pro Datei und Item.

### analyze.ps1

Extrahiert alle einzigartigen Alter→Neuer-Preis-Paare und berechnet logarithmische Regressionsdaten zur Formelbestimmung.

```powershell
.\ps1\analyze.ps1
```

**Ausgabe:** `formula_data.txt` mit Spalten: `Old`, `New`, `ln_Old`, `ln_New`, `sqrt_Old`, `New/sqrt(Old)`

---

## 📊 Statistik der aktuellen Konfiguration

| Metrik | Wert |
|---|---|
| JSON-Dateien | 131+ |
| Kategorien | Fahrzeuge, Waffen, Kleidung, Nahrung, Medizin, Attachments, u.v.m. |
| Enthaltene Mods | Vanilla, Expansion, SNAFU, FOG, CannabisPlus, u.a. |
| Preisänderungen | 4.144 Felder angepasst |
| Richtung | 100% Senkung (0 Erhöhungen) |
| Genauigkeit der Formel | R² = 0.9974 |

---

## 💡 Beispiel-Workflow: Neue Preisanpassung

```powershell
# 1. Hilfe und Referenztabelle anzeigen
.\ps1\PriceConverter.ps1

# 2. Dry-Run auf dem ganzen Ordner (nur Vorschau)
.\ps1\PriceConverter.ps1 "C:\Server\Market" -DryRun

# 3. Mit anderem Exponenten testen
.\ps1\PriceConverter.ps1 "C:\Server\Market" -B 0.65 -DryRun

# 4. Wenn zufrieden – anwenden (Ergebnis in NewMarket/)
.\ps1\PriceConverter.ps1 "C:\Server\Market" -B 0.65

# 5. NewMarket-Dateien auf den Server kopieren
```

---

## 📝 Lizenz

Frei zur Verwendung und Anpassung für DayZ-Server-Administration.
