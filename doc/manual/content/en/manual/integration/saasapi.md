---
title: "Publisher Webservice API"
weight: 70
type: docs
---

{{< profeature "Available in the Pro plan" >}}

The speedata Publisher can be used without local installation.
For this purpose, a so-called Software-as-a-Service solution is available at https://api.speedata.de, which can be used via a REST interface.

In order to access the speedata Publisher API, a valid Pro plan must be available and an API key (token) must be generated in the download area. This key can then be used to access all functions.

## Authentication

All methods whose path starts with `/v0` must be authenticated with a user name:

```shell
curl -u "sdapi_...:" "https://api.speedata.de/v0/.."
```

The colon at `-u` separates the username from the password and is not part of the username.

{{< callout >}}
The username must of course be replaced by your own token, which must be generated at https://download.speedata.de/#account.
{{< /callout >}}

## Overview of the REST methods

| Method | URL | Short description |
| --- | --- | --- |
| GET | [`/available`]({{< relref "saasapi#saasapi-method-available" >}}) | Return 200 OK to check if the server is running. |
| GET | [`/v0/versions`]({{< relref "saasapi#saasapi-method-versions" >}}) | List available versions. |
| POST | [`/v0/publish`]({{< relref "saasapi#saasapi-method-publish" >}}) | Start a publishing process. |
| GET | `/v0/status/<id>` | Get the status of a publishing run. |
| GET | `/v0/wait/<id>` | Wait for the PDF to get written. |
| GET | `/v0/pdf/<id>` | Download the PDF. |


### `/available`

Without version number.
Returns HTTP status 200.

### `/v0/versions`

List all available versions. The response is a JSON array in the following form:

```json
["1.3.12", "1.4.1", "1.5.0-dev"]
```

The version can be used as a query parameter for `/v0/publish`. The following versions are supported:

* All stable versions (e.g. 5.0.2)
* All development versions released since the last stable version (e.g. 5.1.22)

Version numbers with an odd minor number (the second position) are development versions (e.g. 5.1.22).
All others are stable versions (e.g. 5.0.2).

The default is always the latest development version.

### `/v0/publish`

POST a JSON file to `https://api.speedata.de/v0/publish` to start the publishing process

```json
{
    "files": [
        {
            "filename": "layout.xml",
            "contents": "PExheW91dAog..."
        },
        {
            "filename": "data.xml",
            "contents": "PGRhdGE+CiAg..."
        }
    ]
}
```

The file contents is encoded base64.

The answer is in case of success a session id, such as 340416874 encoded as json: `{"id":"340416874"}` with a status code 201.

A version number (or the string `latest`) can be passed as query parameter `version`, which specifies the desired speedata Publisher version. The default is always the latest developer version. Example: `/v0/publish?version=1.2.43`

### `/v0/status/<id>`

| Field | Meaning |
| --- | --- |
| finished | A time stamp in the format “2019-12-05T13:27:29.450219694+01:00” if the run has stopped, otherwise the string ‘null’. |
| errors | The number of errors occured during the publishing run. |
| errormessages | An array of error messages, if any. An error message is a dictionary with the keys “code” and “error”. Se the example. |


```json
{
    "finished": "2019-12-05T13:38:42.855821194+01:00",
    "errors": 1,
    "errormessages": [
        {
            "code": 1,
            "error": "[page 1] Image \"doesnotexist.pdf\" not found!"
        }
    ]
}
```

### `/v0/wait/<id>`

The result is the same as in /v0/status. You don’t need to call wait to make sure the PDF file is finished, you can do a call to /v0/pdf/ which waits for the PDF to complete.

### `/v0/pdf/<id>`

To download the PDF, call `+https://api.speedata.de/v0/pdf/<id>+` and replace the `<id>` with the the id from `/v0/publish`.

## Status codes
The speedata API uses the following status codes:

| Status Code | Meaning |
| --- | --- |
| 200 | Everything went well |
| 201 | The requested publishing run has been created |
| 401 | Unauthorized – Your API key is wrong |
| 404 | API URL does not exist |
| 422 | Something went wrong |


In most error cases, a JSON file confirming to RFC 7807 is sent to the client with the following fields:

| Field | Meaning |
| --- | --- |
| type | A unique URI of an error |
| title | A short description |
| detail | A more detailed description of the problem |
| instance | The request path |
| requestid | A unique id for debugging purposes |


Example:

```json
{
    "detail":"You have provided an incorrect authentication token",
    "instance":"/v0/publish",
    "title":"Not authorized",
    "type":"urn:de:speedata:api:v0:unauthorized",
    "requestid": "1234",
}
```

## Library for the programming language Go

The API is deliberately kept small, so that applications can be quickly created
that use the API. For the programming language Go there is a
library that makes it easier to use the API.

The documentation can be found at [Go dev](https://pkg.go.dev/github.com/speedata/publisher-api), the repository is on GitHub at https://github.com/speedata/publisher-api.
