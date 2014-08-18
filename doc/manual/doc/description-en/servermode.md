title: Server-mode
---

Server-mode
===========

(Experimental)

When the speedata Publisher is started in the server-mode, it expects HTTP-requests on port 5266 (configurable). There is currently only one request-URL to find hyphenation points in text.


API
---

### `/v0/format`

Generates hyphenation points for a text, that is given via POST-request. The text is encoded in XML and can contain mandatory line breaks (`<br class="keep" />`) or mandatory mid-word breaks (`<shy class="keep" />`).

The returned XML has the same format as the request.

The XML-structure of the request and answer must confirm to the following RelqxNG-compact schema:

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


