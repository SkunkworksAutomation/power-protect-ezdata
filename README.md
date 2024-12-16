# PowerProtect ezdata (v19.18)
Create declarative data extracts for PowerProtect Data Manager. This PowerShell7 module will allow you to create data extracts for PowerProtect Data Manager without writing any code. It is very extensible for those with a PowerShell 7 skill set but it is definately not required to use only a very basic knowledge of PowerShell 7 is required (i.e executing cmdlets).

# Use case
- Basic ad hoc reporting against a single rest api endpoint
- Data extraction to csv (this can be used to ingest data into other platforms for robust reporting capabilities)

# Skills requirements
- Knowledge of simple JSON structures
- Knowledge of executing basic PowerShell commands

# Dependencies
- Windows 10 or 11
- PowerShell 7.(latest)

# Output to csv
- No additional dependencies

# Notes
- The csv versions of the reports are not tied to the config. Any custom parameters you need are contained within each report script.

> [!WARNING]
> Some of these data extracts can potentially be very large. Ensure you are adjusting any parameters within reasonable ranges.

# Getting started
- Download the dm.utils.ezdata.psm1 module
- Path to the directory
- PS C:\Reports\customers\ezdata> Import-Module .\dm.utils.ezdata.psm1 -Force
- PS C:\Reports\customers\ezdata> new-configuration
- Follow the on screen prompts

![NewConfiguration1](/Assets/new-configuration1.png)
![NewConfiguration2](/Assets/new-configuration2.png)

- a default report template is created in the templates folder called report1.json

# Default template: report1.json
```
{
  "apiEndpoint": "activities",
  "apiPaging": "serial",
  "apiVersion": 2,
  "fileName": "dm-protection-jobs.csv",
  "sortField": "startTime",
  "sortOrder": "DESC",
  "lookBack": 1,
  "lookBackFormat": "yyyy-MM-ddThh:mm:ss.fffZ",
  "filters": [
    "startTime ge \"{{lookBack}}\"",
    "and category eq \"PROTECT\"",
    "and classType eq \"JOB_GROUP\""
  ],
  "fields": [
    {
      "label": "startTime",
      "value": "startTime",
      "format": "local"
    },
    {
      "label": "activityName",
      "value": "name"
    },
    {
      "label": "jobCategory",
      "value": "category"
    },
    {
      "label": "jobClass",
      "value": "classType"
    },
    {
      "label": "jobDuration",
      "value": "duration",
      "format": "{0:dd}d:{0:hh}h:{0:mm}m:{0:ss}s"
    },
    {
      "label": "preCompSize",
      "value": "stats.preCompBytes",
      "format": "base2"
    },
    {
      "label": "postCompSize",
      "value": "stats.postCompBytes",
      "format": "base10"
    },
    {
      "label": "sizeTransferred",
      "value": "stats.bytesTransferred",
      "format": null
    }
  ]
}

```
# Understanding template: report1.json
- apiEndpoint: The REST API endpoint we want to extract data from
- apiPaging: The paging methodology we want to use - serial, or random.
- - Random paging is more performant but can only retrieve under 10,000 records
- - Serial paging can return greater than 10,000 records