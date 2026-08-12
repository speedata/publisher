---
title: "Server mode (REST API)"
weight: 64
type: docs
---

{{< profeature "Available in the Pro plan" >}}

The Publisher provides an interface that can be used to pass requests for document generation via HTTP. The server mode is started with

```
sp server
```

on the command line. The server mode offers the option to

* transfer data to the server and start a run
* determine status of the run (is the process still running?)
* download finished PDF files
* retrieve protocol and other files from the working directory

{{< callout type="warning" >}}
Server mode is intended for a non-public environment. There are no authentication methods and no mechanisms to protect documents.
{{< /callout >}}

{{< callout type="info" >}}
API version 0 (`/v0/...`) is still available but no longer actively developed.
New integrations should use API version 1 (`/v1/...`).
{{< /callout >}}

The server establishes the connection on the IP address `127.0.0.1` and port `5266`.
The address can be changed with the parameters `address` and `port` in the configuration file or on the command line, see [the appendix about configuration]({{< relref "configuration" >}}).

Example of a configuration file:

```
[server]
port = 9999
address = 0.0.0.0
extra-dir = /var/projects/fonts:/var/projects/images
filter = convertdata.lua
```

An overview of all API methods follows.
The current version number of the API is 1, so all methods are addressed via `http://127.0.0.1:5266/v1/..`.

| Method | URL | Short description |
| --- | --- | --- |
| GET | [`/v1/available`](#available) | Check if the server is running. |
| POST | [`/v1/jobs`](#post-v1jobs) | Start a publishing run. |
| GET | [`/v1/jobs`](#get-v1jobs) | Overview of all publishing runs. |
| GET | [`/v1/jobs/{id}`](#get-v1jobsid) | Status of a publishing run. |
| GET | [`/v1/jobs/{id}/pdf`](#get-v1jobsidpdf) | Retrieve PDF of a publishing run. |
| POST | [`/v1/pdf`](#post-v1pdf) | Send data and receive PDF in one request. |
| GET | [`/v1/jobs/{id}/files/{filename}`](#get-v1jobsidfilesfilename) | Retrieve a file from the working directory. |
| DELETE | [`/v1/jobs/{id}`](#delete-v1jobsid) | Delete a publishing run. |

### Error format

All error responses from the v1 API use the [RFC 9457](https://www.rfc-editor.org/rfc/rfc9457) format (Problem Details for HTTP APIs) with Content-Type `application/problem+json`:

```json
{
  "type": "about:blank",
  "title": "Job not found",
  "status": 404,
  "detail": "No job with id \"123\" exists",
  "instance": "/v1/jobs/123"
}
```

## `/v1/available`

GET: Returns HTTP status 200 with a JSON response:

```json
{"status": "ok"}
```

## `POST /v1/jobs`

Starts a new publishing run. The request body can optionally contain a JSON file in the following format:

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

These files are copied to an empty directory on the server and `sp` is called there.
The return is in the form

```json
{"id": "752869708"}
```

with an HTTP status code 201 (Created).

### Parameters

The following URL parameters can be specified in the POST request:

`vars`
: Sets variables for the Publisher run. Specification in the form `var1=value1,var2=value2,var3=value3...`, but URL-encoded.

`mode`
: Sets the mode for the run. Specification in the form `mode1,mode2,mode3...`, but URL-encoded.

### Example

```bash
curl -X POST "http://127.0.0.1:5266/v1/jobs?vars=myvar%3D12345&mode=a4paper%2Cprint"
```

sets `myvar` to `12345` and enables the modes `a4paper` and `print`. The response contains the job ID:

```json
{"id": "752869708"}
```

## `GET /v1/jobs`

Returns the status of all publishing runs.

```json
{
  "jobs": [
    {
      "id": "1997009134",
      "status": "finished",
      "message": "no errors found",
      "finished": "2016-05-23T11:14:14+02:00"
    },
    {
      "id": "1997329145",
      "status": "processing"
    }
  ]
}
```

Possible values for `status`: `finished`, `failed`, `processing`, `error`.

## `GET /v1/jobs/{id}`

Returns the status of a single publishing run.

If the run is still in progress, HTTP status code **202 (Accepted)** is returned:

```json
{
  "id": "752869708",
  "status": "processing"
}
```

If the run is complete, HTTP status code **200 (OK)** is returned:

```json
{
  "id": "752869708",
  "status": "finished",
  "message": "no errors found",
  "finished": "2015-12-25T12:03:04+01:00"
}
```

If the ID is unknown, HTTP status code **404** is returned with an RFC 9457 error response.

## `GET /v1/jobs/{id}/pdf`

Returns the generated PDF file. The request waits for the publishing process to complete.

### Parameters

`jobname`
: Sets the filename of the PDF output in the HTTP `Content-Disposition` header. Defaults to `publisher.pdf` if not specified.

`keep`
: Set to `true` to keep the working directory after download. By default, the directory is automatically deleted after the PDF is retrieved.

### Example

```bash
curl "http://127.0.0.1:5266/v1/jobs/752869708/pdf?jobname=Contract2026" -o contract.pdf
```

### Return values

200 OK
: PDF was generated without errors. The file is returned with `Content-Type: application/pdf` and a `Content-Disposition` header. The working directory is deleted afterwards, unless `keep=true` is specified.

404 Not Found
: ID invalid.

406 Not Acceptable
: PDF was generated with errors.

## `POST /v1/pdf`

Sends data to the server and receives the PDF in the same request. The data encoding corresponds to [`POST /v1/jobs`](#post-v1jobs), the return values correspond to [`GET /v1/jobs/{id}/pdf`](#get-v1jobsidpdf).

## `GET /v1/jobs/{id}/files/{filename}`

Returns any file from the working directory of a publishing run. Useful e.g. for the protocol file:

```bash
curl "http://127.0.0.1:5266/v1/jobs/752869708/files/publisher-protocol.xml"
```

200 OK
: The file is returned with an automatically detected Content-Type.

404 Not Found
: ID or filename invalid.

## `DELETE /v1/jobs/{id}`

Deletes the working directory of a publishing run.

204 No Content
: Successfully deleted.

404 Not Found
: ID invalid.

### Example

```bash
curl -X DELETE "http://127.0.0.1:5266/v1/jobs/752869708"
```

## Complete example

A typical workflow with the v1 API:

```bash
# 1. Start a job
ID=$(curl -s -X POST "http://127.0.0.1:5266/v1/jobs?vars=mode%3DCONTRACT" | jq -r '.id')
echo "Job started with ID: $ID"

# 2. Check status (HTTP 202 = still running, 200 = finished)
curl -s "http://127.0.0.1:5266/v1/jobs/$ID"

# 3. Download PDF (waits for completion)
#    The working directory is automatically deleted afterwards.
curl -s "http://127.0.0.1:5266/v1/jobs/$ID/pdf?jobname=Contract" -o Contract.pdf
```

If you also need the protocol file, keep the working directory with `keep=true`:

```bash
# 3a. Download PDF, keep working directory
curl -s "http://127.0.0.1:5266/v1/jobs/$ID/pdf?jobname=Contract&keep=true" -o Contract.pdf

# 4. Retrieve protocol file
curl -s "http://127.0.0.1:5266/v1/jobs/$ID/files/publisher-protocol.xml" -o protocol.xml

# 5. Manually delete working directory
curl -s -X DELETE "http://127.0.0.1:5266/v1/jobs/$ID"
```
