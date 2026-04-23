---
title: "speedata Publisher Pro plan"
weight: 110
type: docs
---


The speedata Publisher is available in two plans: Standard and Pro. The Pro plan includes features that are helpful for professional applications:

* Support via e-mail
* [Server-Modus (REST API)]({{< relref "servermode" >}}) (REST API for local networks)
* [Starting the Publisher via the Hotfolder]({{< relref "hotfolder" >}}) (for fully automatic publisher startup)
* [QR codes and barcodes]({{< relref "/reference/barcode" >}})
* Embedding of ZUGFeRD invoices
* Embedding of resources via HTTP(s), e.g. for media databases
* [bleed]({{< relref "cutmarks" >}})

Also included in the Pro plan is access to the [speedata web service]({{< relref "saasapi" >}}), which allows you to use the publisher without local installation.

A comparison of speedata Publisher Standard and Pro can be found [on the product page](https://www.speedata.de/en/product/prices/).

## How do I get the Pro plan?

1. At https://download.speedata.de/register you can create an account in the download area.
2. After successful registration you must select the appropriate plan (monthly / annual payment).

There are two ways to download the Pro plan (assuming a valid Pro plan):

1. If you are logged in to you account in the download area, then you can use the download links to download the ZIP files or the installation packages.

2. Via command line (e.g. wget or curl) you can download the package. For this you have to create a token in the login area and pass it as authentication:
    ```shell
    curl -u sdapi_....:  \
      -O https://download.speedata.de/dl/speedata-publisherpro-linux-amd64-latest.zip
    ```
    or with wget:
    ```shell
    wget --auth-no-challenge  --user sdapi_...  \
       --password ""  https://download.speedata.de/dl/speedata-publisherpro-linux-amd64-latest.zip
    ```

The standard packages can be downloaded as usual without login or token.

## Checking the version

On the command line you can check if you have the downloaded speedata Publisher Pro with

```shell
sp --version
```

The output will be something like this:

```
Version: 4.11.8 (Pro)
```
