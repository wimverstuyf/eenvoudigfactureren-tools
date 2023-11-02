CLI tools for EenvoudigFactureren (https://eenvoudigfactureren.be).

# Installation

Requires Ruby

## Install on Windows

Download and install Ruby from http://rubyinstaller.org/downloads/ (latest version with DevKit).

After installation execute in command prompt:
```
gem install rest-client fileutils yaml json
```

## Install on Linux

```
apt install ruby
gem install rest-client fileutils yaml json
```

# Usage

## Import CODA files

Upload local CODA-files to one or more accounts on EenvoudigFactureren.

### Set up

Update YAML file importcoda.yml.
For every account on EenvoudigFactureren add an account in the YAML file.
Get the API-key from "Access Control" page in the account and add the matching IBAN of the company.
The name of the account is only used for clarity.
A company with multiple IBAN can be added multiple times with the same name and API-key.

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

### Run

Run in command prompt:
```
ruby importcoda.rb
```

CODA files with a different IBAN not listed in the YAML file will to skipped and moved to the out-path.

Run command in scheduler to automatically process CODA files.
