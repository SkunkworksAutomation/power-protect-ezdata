# PowerProtect ezdata (v19.18)
Create declarative data extracts for PowerProtect Data Manager. This PowerShell7 module will allow you to create data extracts for PowerProtect Data Manager without writing any code. It is very extensible for those with a PowerShell 7 skill set but it is definately not required for standard usage.

# Use case
- Basic ad hoc reporting against a single rest api endpoint
- Data extraction to csv (*this can be used to ingest data into other platforms for robust reporting capabilities*)

# Skills requirements
- Knowledge of simple JSON structures
- Knowledge of executing basic PowerShell cmdlets

# Dependencies
- Windows 10 or 11
- PowerShell 7.(latest)

# Output to csv
- No additional dependencies

# Notes
> [!WARNING]
> Some of these data extracts can potentially be very large. Ensure you are adjusting any parameters within reasonable ranges and using the correct paging methodology.

# Getting started
- Download the dm.utils.ezdata.psm1 module
- Path to the directory
- PS C:\Reports\customers\ezdata> **Import-Module .\dm.utils.ezdata.psm1 -Force**
- PS C:\Reports\customers\ezdata> **new-configuration**
- Follow the on screen prompts

![NewConfiguration1](/Assets/new-configuration1.png)
![NewConfiguration2](/Assets/new-configuration2.png)
# Folders
- **configuration**: Where the default configuration and PS credential files reside
- **reports**: Output in csv format from the data extract
- **templates**: Where your extract templates are created and reside
    - a default extract template is created here called report1.json

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
- **apiEndpoint**: The REST API endpoint we want to extract data from
- **apiPaging**: The paging methodology we want to use - random, or serial.
    - **Random paging**: is more performant but can only retrieve under 10,000 records
    - **Serial paging**: can return greater than 10,000 records
- **apiVersion**: the version of the REST API endpoint we are using
- **fileName**: The name of the csv file we want to drop into the reports folder (the prefix will be the IP, or FQDN of the PowerProtect Data Manager server)
- **sortField**: The field we want to sort the data on
- **sortOrder**: ASC, DESC
- **lookBack**: The number of days we want to report against (Todays date - lookBack)
- **lookBackFormat**: UTC, you can use this to set a specified time "yyyy-MM-ddT18:00:00.000Z".
    - In the example above if we are querying the activities REST API based on the activity startTime. The time from the REST API is stored in UTC so based on the lookBack and lookBackFormat it would return every activity with a startTime greater than TODAY at midnight UTC if the offset was -6:00.
- **filters**: Any critera we want to filter on. In the example above we are querying for activities with a startTime greater than or equal to {{lookBack}} with a category of PROTECT (backups), and a classType JOB_GROUP (protection policies)
    - Note: {{lookBack}} is a data binding that is replaced with the value of the lookBack property and converted into a datetime value (Todays date - lookBack).
- **fields**: what fields you want on the report
    - **label**: What you want to call the field in the data extract.
    - **value**: The field name, returned by the REST API that you want the value for. This can be values for unnested, nested and array values. For nested properties simply use the dot path notation.
    - Dot path example (*we are grabbing the stats object and returning the value of its bytesTransferred property*):
    ```
    {
        "label": "sizeTransferred",
        "value": "stats.bytesTransferred",
        "format": null
    }
    ```
    - **format**: format handling for special fields
        - duration: Returned in milliseconds from the REST API, using the format above we can format it as a human readable timespan
        - time: Returned from the REST API in UTC but we can convert it to local time
        - size: Returned in bytes from the REST API but we can convert it up into a human readable format as either base2 (1024), or base10 (1000)

# Run your first extract to the PowerShell 7 console: report1.json
- PS C:\Reports\customers\ezdata> **start-extract -Console**
![StartExtractConsole](/Assets/start-extract-console1.png)

# Run your first extract and export to csv (in the reports directory): report1.json
- PS C:\Reports\customers\ezdata> **start-extract**
![StartExtractCsv](/Assets/start-extract-csv.png)

# Extract from template: report1.json
![report1-data-extract](/Assets/report1-data-extract.png)

# Creating custom extracts / reports
 - PS C:\Reports\customers\ezdata> **new-template**
![custom-extract](/Assets/new-template.png)

- The new-template wizard will ask you a few questions and create a template based on your answers
- If you as respond 'y' to the test data question the code will connect to the first instance of PowerProtect Data Manager
  - Once connected it will query the API endpoint and pull back up to the first 100 records for the configured API endpoint
  - Get a property count for each object contained within the response and return the object with the highest property count
  - It will then write this record to root directory with a number that corresponds with the template number

- Right click and edit .\testdata2.json
  - this test data will contain all of the field names we can select for our report.
- Right click and edit .\templates\report2.json
```
{
  "apiEndpoint": "policies",
  "apiPaging": "random",
  "apiVersion": 3,
  "fileName": "dm-policies.csv",
  "sortField": "name",
  "sortOrder": "DESC",
  "lookBack": 1,
  "lookBackFormat": "yyyy-MM-ddThh:mm:ss.fffZ",
  "filters": [],
  "fields": [
    {
      "label": "label1",
      "value": "value1"
    },
    {
      "label": "label2",
      "value": "value2"
    },
    {
      "label": "label3",
      "value": "value3"
    },
    {
      "label": "label4",
      "value": "value4"
    },
    {
      "label": "label5",
      "value": "value5"
    },
    {
      "label": "label6",
      "value": "value6"
    }
  ]
}
```
- Now lets select the fields we want on our report from testdata2.json
- For the last field value in our template we will showcase how to filter complex nested structures
- Objects can be traversed down the dot (.) path
- Arrays can be queried by object properties contained within the elements, or simply return a positional element
```
{
  "apiEndpoint": "policies",
  "apiPaging": "random",
  "apiVersion": 3,
  "fileName": "dm-policies.csv",
  "sortField": "name",
  "sortOrder": "DESC",
  "lookBack": 1,
  "lookBackFormat": "yyyy-MM-ddThh:mm:ss.fffZ",
  "filters": [],
  "fields": [
    {
      "label": "name",
      "value": "name"
    },
    {
      "label": "purpose",
      "value": "purpose"
    },
    {
      "label": "disabled",
      "value": "disabled"
    },
    {
      "label": "type",
      "value": "type"
    },
    {
      "label": "createdAt",
      "value": "createdAt",
      "format": "local"
    },
    {
      "label": "schedule",
      "value": "objectives|?type eq BACKUP|operations|?backupLevel eq SYNTHETIC_FULL|schedule.recurrence.pattern.type"
    }
  ]
}
```
- Run the the following command to test our template against testdata2.json
- C:\Reports\customers\ezdata> test-extract -ConfigNo 2
![test-extract1](/Assets/test-extract1.png)

- If it looks good then lets run an extract

