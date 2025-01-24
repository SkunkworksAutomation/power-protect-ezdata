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
![StartExtractConsole](/Assets/start-extract-console.png)

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
- Now lets select the fields we want for our report and update each field
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
- Run the the following command to test our configuration
- C:\Reports\customers\ezdata> test-extract -ConfigNo 2
![test-extract1](/Assets/test-extract1.png)



- Now lets say we want to create a data extract on the audit logs
- We can get the values we need for the template right out of a session with PowerProtect Data Manager
- Log into PowerProtect data manager and open your browser debugging tools (typically: f12)
- Select the network tab in the debugging tools
- In the PowerProtect Data Manager UI select Administration -> Audit Logs
- In your debugging tools select the audit-logs node in the name column
![browser-debugging1](/Assets/browser-debugging1.png)
- From the image above we can see that we the value of the apiEndpoint which in our case will be audit-logs
- The apiVersion will be 2
- We can leave the apiPaging set to random as that is the default paging method for the REST API
- Lets change the fileName value to: dm-audit-logs.csv
- Next lets add six some fields to our template which should now look like this...
```
{
  "apiEndpoint": "audit-logs",
  "apiPaging": "random",
  "apiVersion": 2,
  "fileName": "dm-audit-logs.csv",
  "sortField": "sortField",
  "sortOrder": "DESC",
  "lookBack": 1,
  "lookBackFormat": "yyyy-MM-ddThh:mm:ss.fffZ",
  "filters": [
    "sortField ge \"{{lookBack}}\""
  ],
  "fields": [
    {
      "label": "id",
      "value": "id"
    },
    {
      "label": "id",
      "value": "id"
    },
    {
      "label": "id",
      "value": "id"
    },
    {
      "label": "id",
      "value": "id"
    },
    {
      "label": "id",
      "value": "id"
    },
    {
      "label": "id",
      "value": "id"
    },
    {
      "label": "id",
      "value": "id"
    }
  ]
}
```
- Clicking over to the response tab in the browser debugging tools will let you see the fields so we can add some.
![browser-debugging2](/Assets/browser-debugging2.png)
- Now lets select a sortField from the list contained within the content array and set the value of sortField to changedTime
- Now lets replace the sortField in the filters array to changedTime
- Next lets define the first field as changedTime for both label and value
- Change both the label and value for the next field to auditType
- Change both the label and value for the next field to messageID
- Change both the label and value for the next field to messageArgs
- Change both the label and value for the next field to changeDescription
- Change the label for the next field to changedBy and the value to changedBy.username
- Change the label for the next field to changedObject and the value to changedObject.resourceType
- Save the template
- Your template should now look like this...
```
{
  "apiEndpoint": "audit-logs",
  "apiPaging": "random",
  "apiVersion": 2,
  "fileName": "dm-audit-logs.csv",
  "sortField": "changedTime",
  "sortOrder": "DESC",
  "lookBack": 1,
  "lookBackFormat": "yyyy-MM-ddThh:mm:ss.fffZ",
  "filters": [
    "changedTime ge \"{{lookBack}}\""
  ],
  "fields": [
    {
      "label": "changedTime",
      "value": "changedTime"
    },
    {
      "label": "auditType",
      "value": "auditType"
    },
    {
      "label": "messageID",
      "value": "messageID"
    },
    {
      "label": "messageArgs",
      "value": "messageArgs"
    },
    {
      "label": "changeDescription",
      "value": "changeDescription"
    },
    {
      "label": "changedBy",
      "value": "changedBy.username"
    },
    {
      "label": "changedObject",
      "value": "changedObject.resourceType"
    }
  ]
}
```
- Rerun the start-extract cmdlet
- PS C:\Reports\customers\ezdata> **start-extract**
![start-extract-custom](/Assets/start-extract-custom.png)

- Finally lets look at the **dm-audit-logs.csv** file contained within the reports directory
![custom-template-output](/Assets/custom-template-output.png)

# Working with complex data structures
When working with nested data contained within JSON objects you can simply follow the dot (.) path from the root to the desired property.

Example:
```
{
  "node1":{
    "node2": {
      "id": 123456
      "name": "Test"
    }
  }
}
```
In order to access the name property within the nested JSON object above the field configuration in your report.json template would look like this

```
{
  "label": "name",
  "value": "node1.node2.name"
}
```
Now lets take look at a more complicated structure
```
{
  "id": "b6c6e0b6-7358-448c-ae1d-2fe324768219",
  "name": "TestCatalog",
  "catalog":
  [
      {
          "id": 1,
          "name": "Part1",
          "colors": [
              {
                  "id": 1,
                  "color":"green"
              },
              {
                  "id": 2,
                  "color":"yellow"
              }
          ]
      },
      {
          "id": 2,
          "name": "Part2",
          "colors": [
              {
                  "id": 3,
                  "color":"red"
              },
              {
                  "id": 4,
                  "color":"blue"
              }
          ]
      }
  ]
}
```
For this example we want to we want to get to the Part2 color blue so our field configuration within the report.json file would look like this.
```
{
    "label": "defaultPartColor",
    "value": "catalog|?name eq Part2|colors|?id eq 4|color"
}
```
> [!NOTE] 
> Traverse to the catalog array, query for the Part2 name, traverse to the colors array, query for a color with an id of 4, display the color property
## -- OR --
```
{
    "label": "defaultPartColor",
    "value": "catalog|?name eq Part2|colors|?1|color"
}
```
> [!NOTE] 
> Traverse to the catalog array, query for the Part2 name, traverse to the colors array, query for the 2nd element in the array, display the color property

Both of these approaches will work. Please note that if the REST API return nodes within an array in a random order the first approach will net consistent results.

- Filters are seperated by the pipe character |
- Items specified within a filter can be nested, or unnested
- Queries begin with a ?
- Queries apply to array preceeding it in the pipeline **Array|PROPERTY OR POSITIONAL QUERY|value**
- ? followed by a number return the elements position in a zero based array **catalog|?1|name**
- ? followed by a property then followed by **eq**, **ne**, or **match** then followed by a value will query the array based a properties value **catalog|?name eq Part2|name**
- Property and Positional queries can be mixed together  **catalog|?name eq Part2|colors|?1|color**
- Property based queries can currently use the following comparision operators:
  - eq (equals)
  - ne (not equals)
  - match (regex)

![custom-template-output](/Assets/test-extract.png)
