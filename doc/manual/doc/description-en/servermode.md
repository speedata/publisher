title: Server-mode
---

Server-mode
===========

When the speedata Publisher is started in the server-mode (`sp server`), it
expects HTTP-requests on port 5266 (configurable).

The server mode must be used in a restricted environment. The current API (v0)
exposes all PDF files and other private information to all users with access
to the server. Future versions of the API might handle authentication.


## `/available`

Return HTTP-status 200 (OK).


## `/v0/publish`

When called with a POST-request, the speedata Publisher expects  a JSON file in the follwing format:


    {<filename>:<base64 encoded file contents>,
     <filename>:<base64 encoded file contents>,
     ...
     }

for example:

    {"layout.xml":"PD94bWwgdmVyc2lv....",
     "data.xml":"PGRhdGE+CiAgICA8Y29udGVudHM+PCFbQ0RBVEFbPHV..." }

These files are copied into an empty directory and after the request, the program `sp` is called without arguments. The result of the POST request is in the form:

    {"id":"752869708"}

with an HTTP status code 201 (Created).

If the JSON file is defective, the HTTP status code is 400 (bad request) and the returned contents is a text string, such as

    illegal base64 data at input byte 0

### Parameters

A parameter can be specified to set the result name of the PDF (without extension):

`/v0/publish?jobname=myfile` sets the jobname to "myfile", so `/v0/pdf/<id>` returns the data with the given filename (plus the `.pdf`) extension. This is done via the HTTP header `Content-Disposition`. If the parameter is not supplied, the `jobname` is taken from the file `publisher.cfg`. If the file is not supplied or if the parameter is not set in that file, the `jobname` is set to `publisher`.

You can also submit additional variables: `/v0/publish?vars=var1%3Dvalue1`. This is similar to the command line parameter `--var`.  The parameter is URL-encoded in the form `var1=value1,var2=value2,var3=value3...`.

## `/v0/delete/<id>`

GET: Remove the directory for this ID. Returns 200 if the ID is valid, 404 if not.


## `/v0/publish/<id>`

A GET request with an id from the aforementioned POST request returns a JSON file with the following contents:

    {"status":"ok","path":"/path/to/publisher.pdf","blob":"<base64 encoded PDF file>",
     finished:"2015-03-03T13:12:55+01:00"}

or, in case of an error, if the id is unknown:

    {"status":"error","path":"","blob":"id unknown"}

If the PDF file is not finished yet:

    {"status":"error","path":"","blob":"in progress"}

The directory of the publishing run will be deleted right after the request, unless the URL has the suffix `?delete=false`.


## `/v0/pdf/<id>`

A GET request with an id from the aforementioned POST request. In case of success, the PDF file gets returned with a 200 OK status. The request waits for the PDF file to be ready. On error, the answer is an error code:

Status code  | Description
------------|--------------
200 OK              | PDF rendered OK
404 Not Found       | Id is invalid
406  Not Acceptable | PDF has errors


## `/v0/data/<id>`

Return the data file that has been copied to the server before. The format can be set with the URL parameter `format`:

Format | Description
-------|-------------
`json` or `JSON` | Return a JSON-file such as `{"contents":"<XML Text>"}`
`base64` | The result is an XML file, that is encoded base64 (`PGRhdGE+CiAgICA8....hPgo=`)
(no format) | Returns the XML file (`<data>...</data>`)

Example: `http://127.0.0.1:5266/v0/layout/1347678770?format=base64`

## `/v0/layout/<id>`

Return the layout file that has been copied to the server before. The format can be set with the URL parameter `format`:

Format | Description
-------|-------------
`json` or `JSON` | Return a JSON-file such as `{"contents":"<XML Text>"}`
`base64` | The result is an XML file, that is encoded base64 (`PGRhdGE+CiAgICA8....hPgo=`)
(no format) | Returns the XML file (`<Layout>...</Layout>`)

Example: `http://127.0.0.1:5266/v0/layout/1347678770?format=base64`

## `/v0/statusfile/<id>`

Return the file `publisher.status` that has been created during the last run. The format can be set with the URL parameter `format`:

Format | Description
-------|-------------
`json` or `JSON` | Return a JSON-file such as `{"contents":"<XML Text>"}`
`base64` | The result is an XML file, that is encoded base64 (`PGRhdGE+CiAgICA8....hPgo=`)
(no format) | Returns the XML file (`<Status>...</Status>`)

Example: `http://127.0.0.1:5266/v0/statusfile/1347678770?format=base64`


## `/v0/status`

Return the status for all publishing runs, that were started with `/v0/publish`.

The returned JSON file has the following format:

    {
      "1997009134": {
        "errorstatus": "ok",
        "result": "finished",
        "message": "no errors found",
        "finished": "2016-05-23T11:14:14+02:00"
      },
      "1997329145": {
        "errorstatus": "ok",
        "result": "finished",
        "message": "no errors found",
        "finished": "2016-05-23T11:14:14+02:00"
      }
    }

See `/v0/status/<id>` for the meaning of the fields.


## `/v0/status/<id>`

Determines the current status of the publishing run, which was POSTed to `/v0/publish`.

The returned JSON has the following keys:

Key           | Description
--------------|--------------
`errorstatus` | Is the request valid? Possible answers are `error` and `ok`. If it is `error`, the value of the `message` contains the reason for the error, the value for the key `result` is without any meaning.
`result`      | Contains `failed` if the PDF file is created but with errors. `not finished` if the PDF file is not finished, `ok` if everything went fine.
`message`     | Contains an informal message, for example `no errors found` or `2 errors occurred during publishing run`.
`finished`    | Time stamp when the PDF was finished written to. Format is RFC3339, for example `2015-12-25T12:03:04+01:00`.


## `/v0/format`

Generates hyphenation points for a text, that is given via POST-request. The text is encoded in XML and can contain mandatory line breaks (`<br class="keep" />`) or mandatory mid-word breaks (`<shy class="keep" />`).

The returned XML has the same format as the request.

The XML-structure of the request and answer must confirm to the following RelaxNG Compact schema:

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


