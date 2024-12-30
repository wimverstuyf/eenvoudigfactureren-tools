CLI tools for EenvoudigFactureren (https://eenvoudigfactureren.be).

# Installation

Requires Ruby

## Install on Windows

Download and install Ruby from http://rubyinstaller.org/downloads/ (latest version with DevKit).

After installation execute in command prompt:
```
gem install rest-client fileutils yaml json ffi
```

## Install on Linux

```
apt install ruby
gem install rest-client fileutils yaml json ffi
```

# Usage

## Import CODA files

Upload local CODA-files to one or more accounts on EenvoudigFactureren.

### Setup

There are several scenarios for setting up the script. Update YAML file importcoda.yml according to your scenario.

An API-key is required to access the account on EenvoudigFactureren. Get the API-key from the "Access Control" page in the account.

Paths can use the variable {yyyy} to set the current year.

#### Setup for one account

Set up the script to upload CODA files for a single account.

Example importcoda.yml:

```
domain: eenvoudigfactureren.be
paths:
  in: c:\path\to_process
  out: c:\path\done
apikey: MY-APIKEY-1
```

#### Setup for multiple accounts in one directory

Upload CODA files for multiple accounts. All CODA files are added to a single directory. CODA files are filtered based on the IBAN of the account.

Remarks:
- For every account on EenvoudigFactureren add an account in the YAML file.
- The name of the account is only used for clarity.
- An account with multiple IBAN can be added multiple times with the same name and API-key.
- CODA files with a IBAN not listed will be skipped and moved to the out-path.

Example importcoda.yml:

```
domain: eenvoudigfactureren.be
paths:
  in: c:\path\to_process
  out: c:\path\done
accounts:
  - 
    name: Company 1
    apikey: MY-APIKEY-1
    iban: BE1111111111111
  -
    name: Company 2
    apikey: MY-APIKEY-2
    iban: BE2222222222222
```

#### Setup with separate directory per account

Upload CODA files for multiple accounts. Per account a separate directory for new CODA files is used.

Remarks:
- For every account on EenvoudigFactureren add an account in the YAML file.
- The name of the account is only used for clarity.

Example importcoda.yml:

```
domain: eenvoudigfactureren.be
accounts:
  - 
    name: Company 1
    apikey: MY-APIKEY-1
    paths:
      in: c:\path\company1\to_process
      out: c:\path\company1\done
  -
    name: Company 2
    apikey: MY-APIKEY-2
    paths:
      in: c:\path\company2\to_process
      out: c:\path\company2\done
```

### Run

Run in command prompt:
```
ruby importcoda.rb
```

Once processed the CODA file will be moved to the out-path.

Run command in scheduler to automatically process CODA files.

## Download files

Download invoices or other documents as PDF or UBL file for one or more accounts on EenvoudigFactureren.

### Setup

There are several scenarios for setting up the script. Update YAML file download.yml according to your scenario.

An API-key is required to access the account on EenvoudigFactureren. Get the API-key from the "Access Control" page in the account.

You can download files for invoices, receipts, quotes, orders, deliveries, paymentrequests and customdocuments.

The format is pdf by default. For invoices you can also set ubl or peppol as format.

The paths can use the variable {yyyy}, {mm} and {dd} to set the current date.

You can optionally filter the documents by date (from and until) and whether a tag has been set for the document. The tag is mainly used to filter invoices that have not yet been sent to the accountant (tag: not:accountant).
For dates you can use the wildcards: MONTH, PREVMONTH, NEXTMONTH, QUARTER, PREVQUARTER, NEXTQUARTER, YEAR, PREVYEAR, NEXTYEAR

For invoices you can perform the "mark as sent to accountant" action. This will set the invoices as sent to the accountant. In combination with "tag: not:accountant" this will enable you to only download the invoice once.

#### Setup for one account

Set up the script to download files for a single account.

Example download.yml:

```
domain: eenvoudigfactureren.be
path: c:\path\{yyyy}\{mm}
apikey: MY-APIKEY-1
type: invoices
format: pdf
filter:
  from: PREVMONTH
  until: MONTH
  tag: not:accountant
action: mark-sent-accountant
```

#### Setup for multiple accounts

Download files for multiple accounts.

Remarks:
- For every account on EenvoudigFactureren add an account in the YAML file.
- The name of the account is only used for clarity.
- Path, filters and action can be set globally or per account.

Example download.yml:

```
domain: eenvoudigfactureren.be
type: invoices
format: ubl
filter:
  from: PREVQUARTER
  tag: not:accountant
action: mark-sent-accountant
accounts:
  - 
    name: Company 1
    apikey: MY-APIKEY-1
    path: c:\path\company1\{yyyy}\{mm}
    filter:
      from: 2024-01-01
  -
    name: Company 2
    apikey: MY-APIKEY-2
    path: c:\path\company2\{yyyy}\{mm}
```

### Run

Run in command prompt:
```
ruby download.rb
```

Run command in scheduler to automatically download files.