# PowerProtect ezdata (v19.18)
Create declarative data extracts for PowerProtect Data Manager. This PowerShell7 module will allow you to create data extracts for PowerProtect Data Manager without writing any code. It is very extensible for those with a PowerShell 7 skill set but it is definately not required to use only a very basic knowledge of PowerShell 7 is required (i.e executing cmdlets). 

# Skills requirements
- Knowledge of simple JSON structures
- Knowledge of executing basic PowerShell commands

# Dependencies
- Windows 10 or 11
- PowerShell 7.(latest)

# Output to Csv
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
![NewConfiguration](/Assets/new-configuration.png)