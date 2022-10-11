# GoSelector

Database Column Selectivity is used as a guide by SQL Engine to influence choice of indexes for queries.
Implemented values maybe have already been added to distributed code for example by:
```
Do $SYSTEM.SQL.Stats.Table.SetFieldSelectivity("TEST","PropertyLen2","T1","5.1%")
```
Affects class storage definition adding: 
```
<Property name="T1">
<Selectivity>5.1%</Selectivity>
</Property>
```

This scheduled Task:
* Does NOT modify Table / Class definitions
* Extracts existing column selectivity values found in an environment
* Profiles corresponding data values
* Generates a report of Column implemented selectivity versus actual ratio of distinct values
* Is not intended to replace or compete with other utilities

Can Use Task Schedule Output file option to create report file.
```
set task=##class(alwo.GoSelector).%New()
set task.ClassNamePattern="1""TEST."".E"
do task.OnTask()
```

| Classname | SQL_TableName | Property | SQL_FieldName | Code_Selectivity | RecordCount | Count_DistinctValues | Calculated_Ratio |
|-----------|---------------|----------|---------------|------------------|-------------|----------------------|------------------|
| TEST.PropertyLen | TEST.PropertyLen | Def | Def | 2.5% | 3 | 3 | 33.33% |
| TEST.PropertyLen2 | TEST.PropertyLen2 | T1 | T1 | 5.1% | 7 | 6 | 16.67% |
| TEST.PropertyLen2 | TEST.PropertyLen2 | T2 | T2 | 5.2% | 7 | 5 | 20.00% |
| TEST.PropertyLen2 | TEST.PropertyLen2 | T3 | T3 | 5.3% | 7 | 4 | 25.00% |
| TEST.PropertyLen2 | TEST.PropertyLen2 | T4 | T4 | 5.4% | 7 | 3 | 33.33% |
| TEST.PropertyLen2 | TEST.PropertyLen2 | T5 | T5 | 5.5% | 7 | 3 | 33.33% |

Hope this utility may inspire reuse for other developer reporting needs.
