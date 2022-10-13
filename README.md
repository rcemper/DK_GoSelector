# GoSelector
---
## Installation with ZPM

If the current ZPM instance is not installed, then in one line you can install the latest version of ZPM even with a proxy.
```
s r=##class(%Net.HttpRequest).%New(),proxy=$System.Util.GetEnviron("https_proxy") Do ##class(%Net.URLParser).Parse(proxy,.pr) s:$G(pr("host"))'="" r.ProxyHTTPS=1,r.ProxyTunnel=1,r.ProxyPort=pr("port"),r.ProxyServer=pr("host") s:$G(pr("username"))'=""&&($G(pr("password"))'="") r.ProxyAuthorization="Basic "_$system.Encryption.Base64Encode(pr("username")_":"_pr("password")) set r.Server="pm.community.intersystems.com",r.SSLConfiguration="ISC.FeatureTracker.SSL.Config" d r.Get("/packages/zpm/latest/installer"),$system.OBJ.LoadStream(r.HttpResponse.Data,"c")
```
If ZPM is installed, then ZAPM can be set with the command
```
zpm:USER>install alwo-goselector
```
## Installation with Docker

## Prerequisites
Make sure you have [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git) and [Docker desktop](https://www.docker.com/products/docker-desktop) installed.

## Installation 
Clone/git pull the repo into any local directory

```
$ git clone https://github.com/alexatwoodhead/GoSelector
```

Open the terminal in this directory and run:

```
$ docker-compose build
```

3. Run the IRIS container with your project:

```
$ docker-compose up -d
```

## How to Test it
Open IRIS terminal:

```
$ docker-compose exec iris iris session iris


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
