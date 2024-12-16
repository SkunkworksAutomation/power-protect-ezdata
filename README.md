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
- apiPaging: The paging methodology we want to use - random, or serial.
    - Random paging: is more performant but can only retrieve under 10,000 records
    - Serial paging: can return greater than 10,000 records
- apiVersion: the version of the REST API endpoint we are using
- fileName: The name of the csv file we want to drop into the reports folder (the prefix will be the IP, or FQDN of the PowerProtect Data Manager server)
- sortField: The field we want to sort the data on
- sortOrder: ASC, DESC
- lookBack: The number of days we want to report against (Todays date - lookBack)
- lookBackFormat: UTC, you can use this to set a specified time "yyyy-MM-ddT18:00:00.000Z".
    - In the example above if we are querying the activities REST API based on the activity startTime. The time from the REST API is stored in UTC so based on the lookBack and lookBackFormat it would return every activity with a startTime greater than TODAY at midnight UTC if the offset was -6:00.
- filters: Any critera we want to filter on. In the example above we are querying for activities with a startTime greater than or equal to {{lookBack}} with a category of PROTECT (backups), and a classType JOB_GROUP (protection policies)
    - Note: {{lookBack}} is a data binding that is replaced the value of the lookBack property and converted into a datetime value (Todays date - lookBack).
- fields: what fields you want on the report
    - label: What you want to call the field in the data extract.
    - value: The field name, returned by the REST API that you want the value for. This can be values for unnested, nested and array values. For nested properties simply use the dot path notation.
    - Dot path example (we are grabbing the stats object and returning the value of its bytesTransferred property):
    ```
    {
        "label": "sizeTransferred",
        "value": "stats.bytesTransferred",
        "format": null
    }
    ```
    - format: format handling for special fields (Duration, Time, Size)
        - Duration: Returned in miliseconds from the REST API, using the format above we can format it as a human readable timespan
        - Time: Returned from the REST API in UTC but we can convert it to local time
        - Size: Returned in bytes from the REST API but we can convert it up into a human readable format as either base2 (1024), or base10 (1000)