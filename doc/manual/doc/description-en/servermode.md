title: Server-mode
---

Server-mode
===========

(Experimental)

When the speedata Publisher is started in the server-mode (`sp server`), it expects HTTP-requests on port 5266 (configurable). All of these API calls are experimental. So expect changes.

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

`/v0/publish?jobname=myfile` sets the jobname to "myfile", so `/v0/pdf/<id>` returns the data with the given filename (plus the `.pdf`) extension. This is done via the HTTP header `Content-Disposition`.



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


## `/v0/status/<id>`

Determines the current status of the publishing run, which was POSTed to `/v0/publish`.

The returned JSON has the following keys:

Key           | Description
--------------|--------------
`errorstatus` | Is the request valid? Possible answers are `error` and `ok`. If it is `error`, the value of the `message` contains the reason for the error, the value for the key `result` is without any meaning.
`result`      | Contains `failed` if the PDF file is created but with errors. `not finished` if the PDF file is not finished, `ok` if everything went fine.
`message`     | Contains an informal message, for example `no errors found` or `2 errors occurred during publishing run`.



## `/v0/format`

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


