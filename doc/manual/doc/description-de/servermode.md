title: Server-Modus
---

Server-Modus
============

(Experimentell)

Wird der speedata Publisher im Server-Modus gestartet, erwartet das Programm HTTP-Anfragen auf Port 5266 (konfigurierbar). Derzeit gibt es eine Anfrage-URL um Trennstellen zu ermitteln.

API
---

### `/v0/format`

Erzeugt Trennstellen für einen Text, der per POST-Request übergeben wird. Der Text wird mit XML kodiert und kann feste Umbrüche (`<br class="keep" />`) oder Trennvorschläge (`<shy class="keep" />`) enthalten.

Die Rückgabe erfolgt in demselben Format wie die Anfrage.

Die XML-Struktur der Anfrage als auch der Rückgabe muss folgendem RelaxNG-Compact-Schema entsprechen:

    namespace a = "http://relaxng.org/ns/compatibility/annotations/1.0"
    start =
      element root {
        element text {
          (attribute hyphenate-limit-before { xsd:unsignedInt },
           attribute hyphenate-limit-after { xsd:unsignedInt })?,
          mixed {
            element br {
              attribute class { "keep" | "soft" }?,
              empty
            }+,
            element shy {
              attribute class { "keep" | "soft" }?,
              empty
            }+
          }
        }+
      }


