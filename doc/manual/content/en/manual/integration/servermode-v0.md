---
title: "Server mode: API v0"
linktitle: "Server mode (API v0)"
weight: 65
type: docs
---

{{< profeature "Available in the Pro plan" >}}

This page describes the older version 0 of the server API (`/v0/...`).
It is still available but no longer actively developed.
New integrations should use [API version 1]({{< relref "servermode" >}}).
Starting the server, address, port and configuration are described there and apply to both versions.

{{< callout type="warning" >}}
Server mode is intended for a non-public environment. There are no authentication methods and no mechanisms to protect documents.
{{< /callout >}}

All methods are addressed via `http://127.0.0.1:5266/v0/...`, only `/available` has no version number.

| Method | URL | Short description |
| --- | --- | --- |
| GET | [`/available`](#available) | Check if the server is running. |
| POST | [`/v0/publish`](#post-v0publish) | Send data to the server to start a publishing run. |
| GET | [`/v0/publish/<id>`](#get-v0publishid) | Get the PDF and the status file as JSON. |
| GET | [`/v0/pdf/<id>`](#get-v0pdfid) | Wait for the completion of a PDF and download it. |
| POST | [`/v0/pdf`](#post-v0pdf) | Send data and receive the PDF in the same request. |
| GET | [`/v0/data/<id>`](#get-v0dataid) | Load the `data.xml` from the publishing run. |
| GET | [`/v0/layout/<id>`](#get-v0layoutid) | Load the `layout.xml` from the publishing run. |
| GET | [`/v0/statusfile/<id>`](#get-v0statusfileid) | Load the status file (`publisher.status`) from the publishing run. |
| GET | [`/v0/protocol/<id>`](#get-v0protocolid) | Load the protocol file (`publisher-protocol.xml`) from the publishing run. |
| GET | [`/v0/status`](#get-v0status) | Overview of all publishing runs. |
| GET | [`/v0/status/<id>`](#get-v0statusid) | Status of a publishing run. |
| GET | [`/v0/delete/<id>`](#get-v0deleteid) | Delete a publishing run. |

Error responses of the v0 API have no common format. Depending on the method, a JSON object, a short text or just an HTTP status code is returned.

## `GET /available` {#available}

Without version number.
Returns the HTTP status 200 with an empty body.

## `POST /v0/publish` {#post-v0publish}

Starts a publishing run. The request body contains a JSON file in the following format:

```json
{
  "<filename>": "<base64 encoded content>",
  "<filename>": "<base64 encoded content>"
}
```

such as

```json
{
  "layout.xml": "PD94bWwgdmVyc2lv....",
  "data.xml": "PGRhdGE+CiAgICA8Y29udGVudHM+PCFbQ0RBVEFbPHV..."
}
```

The body can also be empty if no files need to be transferred (e.g. when layout and data are provided via `extra-dir`).
Only the last part of each file name (without directory) is used.

These files are copied to an empty directory on the server and `sp` is called there.
The return is in the form

```json
{"id":"752869708"}
```

with an HTTP status code 201 (Created).

400 Bad Request
: The body is not valid JSON (text `JSON encoding error`) or a file name is unusable (text `Invalid file name "..."`).

500 Internal Server Error
: Internal error, for example when a file content is not valid base64.

### Parameters

The following URL parameters can be specified in the POST request:

`jobname`
: Sets the name of the PDF file that is suggested when downloading via `/v0/pdf/<id>` (HTTP header `Content-Disposition`).
  If not given, the `jobname` entry of an uploaded `publisher.cfg` file is used, otherwise `publisher`.

`vars`
: Sets variables for the Publisher run. Specification in the form `var1=value1,var2=value2,var3=value3...`, but URL-encoded.

`mode`
: Sets the mode for the run. Specification in the form `mode1,mode2,mode3...`, but URL-encoded.

### Example

```bash
curl -X POST --data @job.json \
  "http://127.0.0.1:5266/v0/publish?vars=myvar%3D12345&mode=a4paper%2Cprint"
```

sets `myvar` to `12345` and enables the modes `a4paper` and `print`.

## `GET /v0/publish/<id>` {#get-v0publishid}

Returns the result of a run started with `POST /v0/publish` as a JSON file. The request does not wait for the run to finish.

```json
{
  "status": "ok",
  "path": "/path/to/publisher.pdf",
  "blob": "<base64 encoded PDF>",
  "statusfile": "<base64 encoded file publisher.status>",
  "finished": "2015-03-03T13:12:55+01:00",
  "output": "<unencoded output of the sp run>"
}
```

`status`
: `ok` or `error`.

`path`
: Path to the PDF file on the server.

`blob`
: The PDF file, base64 encoded. In case of an error a short error message.

`statusfile`
: The file `publisher.status`, base64 encoded. Among other things it contains the number of errors.

`finished`
: Time of completion in RFC 3339 format.

`output`
: The output of the `sp` run (not encoded).

Important: `status` is `ok` even if errors occurred during the run, as long as a PDF file was created. Whether the run was free of errors can be read from the status file (field `statusfile`) or determined with [`/v0/status/<id>`](#get-v0statusid).

If the id is unknown, the HTTP status code 400 is returned:

```json
{"status":"error","path":"","blob":"id unknown","statusfile":"","finished":"","output":""}
```

If the run has not finished yet, the HTTP status code 404 is returned:

```json
{"status":"error","path":"","blob":"not finished","statusfile":"","finished":"","output":""}
```

If no PDF file was created, `status` is `error`, `path` and `blob` are empty and `output` contains the output of the run.

The working directory of the run is deleted after this request once the run has finished, unless the URL contains the parameter `delete` with the value `false`.

There can be more fields in the JSON response in future versions.

## `GET /v0/pdf/<id>` {#get-v0pdfid}

Returns the PDF file of the run with the id from `POST /v0/publish`. The request waits for the publishing process to be completed.
The file name in the HTTP header `Content-Disposition` is the `jobname` from the POST request or from `publisher.cfg`, otherwise `publisher.pdf`.

200 OK
: PDF was generated without errors. The file is returned with `Content-Type: application/pdf`.

404 Not Found
: Invalid id.

406 Not Acceptable
: PDF was generated with errors. The file is not returned.

The working directory is deleted after this request (also with 406), unless the URL contains the parameter `delete` with the value `false`.

### Example

```bash
curl "http://127.0.0.1:5266/v0/pdf/752869708?delete=false" -o publisher.pdf
```

## `POST /v0/pdf` {#post-v0pdf}

Sends data to the server and receives the PDF in the same request. The encoding of the data and the URL parameters are the same as for [`POST /v0/publish`](#post-v0publish), the return values are the same as for [`GET /v0/pdf/<id>`](#get-v0pdfid).

If the data cannot be stored, the same HTTP status codes as for `POST /v0/publish` are returned (400 or 500), but the response always contains the text `Internal error 021`.

## `GET /v0/data/<id>` {#get-v0dataid}

Returns the data file `data.xml` that was previously copied to the server. The format can be specified using the URL parameter `format`, for example `http://127.0.0.1:5266/v0/data/1347678770?format=base64`:

`json` or `JSON`
: Returns a JSON file in the format `{"contents":"<XML Text>"}`

`base64`
: Returns the XML file base64 encoded (`PGRhdGE+CiAgICA8...hPgo=`)

(not specified)
: Returns the XML file unchanged (`<data>...</data>`) with `Content-Type: application/xml`

If the id is unknown, the HTTP status code 404 is returned. If the file does not exist, the HTTP status code 200 is returned with the text `Internal error`.

## `GET /v0/layout/<id>` {#get-v0layoutid}

Returns the layout file `layout.xml` that was previously copied to the server. The parameter `format` and the return values are the same as for [`/v0/data/<id>`](#get-v0dataid).

## `GET /v0/statusfile/<id>` {#get-v0statusfileid}

Returns the file `publisher.status` created by the run (`<Status>...</Status>`). The parameter `format` and the return values are the same as for [`/v0/data/<id>`](#get-v0dataid).

## `GET /v0/protocol/<id>` {#get-v0protocolid}

Returns the file `publisher-protocol.xml` created by the run. The parameter `format` and the return values are the same as for [`/v0/data/<id>`](#get-v0dataid).

## `GET /v0/status` {#get-v0status}

Returns the status of all publishing runs whose working directory still exists and contains a file `layout.xml`.
The keys of the JSON object are the ids of the runs:

```json
{
  "1997009134": {
    "errorstatus": "ok",
    "result": "finished",
    "message": "no errors found",
    "finished": "2016-05-23T11:14:14+02:00"
  },
  "1997329145": {
    "errorstatus": "ok",
    "result": "not finished",
    "message": "",
    "finished": ""
  }
}
```

The individual fields have the same meaning as described under [`/v0/status/<id>`](#get-v0statusid).

## `GET /v0/status/<id>` {#get-v0statusid}

Determines the status of a publishing run that was started with a POST request to `/v0/publish`.

```json
{
  "errorstatus": "ok",
  "result": "failed",
  "message": "2 errors occurred during publishing run",
  "finished": "2015-12-25T12:03:04+01:00"
}
```

The returned JSON file has the following keys:

`errorstatus`
: Is the request valid? Possible values are `ok` and `error`. With `error`, `message` contains the reason for the error, for example `id "123" unknown`.

`result`
: `finished` if the run ended without errors, `failed` if errors occurred, `not finished` if the publishing process is still running, and `error` for an unknown id.

`message`
: Contains an informal message about the result, for example `no errors found` or `2 errors occurred during publishing run`.

`finished`
: Contains the timestamp when the PDF was finished. The format corresponds to RFC 3339, for example `2015-12-25T12:03:04+01:00`.

If the run has finished (`finished` or `failed`), the HTTP status code 200 is returned.
If the process is still running or the id is unknown, the HTTP status code is 400.

## `GET /v0/delete/<id>` {#get-v0deleteid}

Deletes the working directory with this id. Returns 200 if the id exists, 404 if not.

## Moving to API v1

| v0 | v1 |
| --- | --- |
| `GET /available` | `GET /v1/available` |
| `POST /v0/publish` | `POST /v1/jobs` |
| `GET /v0/publish/<id>` | `GET /v1/jobs/{id}` and `GET /v1/jobs/{id}/pdf` |
| `GET /v0/pdf/<id>` | `GET /v1/jobs/{id}/pdf` (`keep=true` instead of `delete=false`) |
| `POST /v0/pdf` | `POST /v1/pdf` |
| `GET /v0/data/<id>`, `/v0/layout/<id>`, `/v0/statusfile/<id>`, `/v0/protocol/<id>` | `GET /v1/jobs/{id}/files/{filename}` |
| `GET /v0/status` | `GET /v1/jobs` |
| `GET /v0/status/<id>` | `GET /v1/jobs/{id}` |
| `GET /v0/delete/<id>` | `DELETE /v1/jobs/{id}` |

In v1, the parameter `jobname` is not given when starting the run but when downloading the PDF (`GET /v1/jobs/{id}/pdf`).
