# Templates
| Name        | Filter                                                                                         |
|:-----------:|:-----------------------------------------------------------------------------------------------|
| activities1 | classType eq "JOB" and category eq "BACKUP" and startedAt ge "{{lookBack}}"                    |
| activities2 | classType eq "JOB_GROUP" and category eq "BACKUP" and startedAt ge "{{lookBack}}"              |
| alerts1     | severity eq "CRITICAL" and lastOccurrenceTime gt "{{lookBack}}" and acknowledgement.acknowledgeState eq "UNACKNOWLEDGED" |
| assets1     | type eq "VMWARE_VIRTUAL_MACHINE" and lastDiscoveryStatus in ("NEW","DETECTED","NOT_DETECTED")  |
| assets2     | type eq "FILE_SYSTEM" and lastDiscoveryStatus in ("NEW","DETECTED","NOT_DETECTED")             |
| assets3     | type eq "MICROSOFT_SQL_DATABASE" and lastDiscoveryStatus in ("NEW","DETECTED","NOT_DETECTED")  |
| assets4     | type eq "ORACLE_DATABASE" and lastDiscoveryStatus in ("NEW","DETECTED","NOT_DETECTED")         |
| audit-logs1 | changedTime ge "{{lookBack}}"                                                                 |