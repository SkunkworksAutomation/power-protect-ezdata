# Report Templates
| Name        | Filter                                                                                         |
|:-----------:|:-----------------------------------------------------------------------------------------------|
| assets1     | type eq "VMWARE_VIRTUAL_MACHINE" and lastDiscoveryStatus in ("NEW","DETECTED","NOT_DETECTED")  |
| assets2     | type eq "FILE_SYSTEM" and lastDiscoveryStatus in ("NEW","DETECTED","NOT_DETECTED")             |
| assets3     | type eq "MICROSOFT_SQL_DATABASE" and lastDiscoveryStatus in ("NEW","DETECTED","NOT_DETECTED")  |
| assets4     | type eq "ORACLE_DATABASE" and lastDiscoveryStatus in ("NEW","DETECTED","NOT_DETECTED")         |
| activities1 | classType eq "JOB" and category eq "BACKUP" and startedAt ge "2025-10-26T16:13:49.120Z"        |