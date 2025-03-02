/// <pre> 
/// Copyright (c) Alex Woodhead 2022
/// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
/// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
/// License MIT
/// Source: https://github.com/alexatwoodhead/GoSelector
/// Version: 1.0
/// </pre>
/// Selectivity is used as a guide by SQL Engine to influence choice of indexes for queries.<br/>
/// Implemented values maybe have been added for example by:
/// <Example>
/// Do $SYSTEM.SQL.Stats.Table.SetFieldSelectivity("TEST","PropertyLen2","T1","5.1%")
/// </Example>
/// Affects class storage definition adding: 
/// <example>
/// <Property name="T1">
/// <Selectivity>5.1%</Selectivity>
/// </Property>
/// </example>
/// 
/// This scheduled Task:
/// <ul>
/// <li>Does NOT modify Table / Class definitions</li>
/// <li>Extracts existing column selectivity values found in an environment</li>
/// <li>Profiles corresponding data values</li>
/// <li>Generates a report of Column implemented selectivity versus actual ratio of distinct values.</li>
/// <li>Is not intended to replace or compete with other utilities</li></ul>
/// </ul>
/// Hope it may find code reuse for other developer reporting needs<br/>
/// 
/// Can Use Task Schedule Output file option to create report file.
/// 
/// <example>
/// set task=##class(alwo.GoSelector).%New()
/// set task.ClassNamePattern="1""TEST."".E"
/// do task.OnTask()
/// 
/// Classname,SQL_TableName,Property,SQL_FieldName,Code_Selectivity,RecordCount,Count_DistinctValues,Calculated_Selectivity
/// TEST.PropertyLen,TEST.PropertyLen,Def,Def,2.5%,3,3,33.33%
/// TEST.PropertyLen2,TEST.PropertyLen2,T1,T1,5.1%,7,6,16.67%
/// TEST.PropertyLen2,TEST.PropertyLen2,T2,T2,5.2%,7,5,20.00%
/// TEST.PropertyLen2,TEST.PropertyLen2,T3,T3,5.3%,7,4,25.00%
/// TEST.PropertyLen2,TEST.PropertyLen2,T4,T4,5.4%,7,3,33.33%
/// TEST.PropertyLen2,TEST.PropertyLen2,T5,T5,5.5%,7,3,33.33%
/// </example>
Class alwo.GoSelector Extends %SYS.Task.Definition
{

/// An ObjectScript Pattern expression that match class names to analyze 
/// <ul>
/// <li>"1""User."".E" - Matches ALL classes in the User package.</li>
/// </ul>
/// Double Quote escaped with second double quote as with object script string expressions
Property ClassNamePattern As %String(MAXLEN = 10000) [ InitialExpression = "1""User."".E" ];

/// This method is responsible for executing the task.<br>
/// At the scheduled time, the Task Manager creates an instance of this object,
/// sets any property values using the stored "Settings" for the task, and then
/// invokes this method to execute the task.<br>
/// In order to execute a real task, override this method in a subclass.
Method OnTask() As %Status
{
	kill ^||SEL,^||SELo
	set pattern=..ClassNamePattern
	
	// Find eixstig SQL Tables with implemented SQL selectivity values 
	set rs=##class(%ResultSet).%New("%DynamicQuery:SQL")
	set tSC=rs.Prepare("SELECT %NOLOCK parent->parent as classname,parent->Name as storage,Name as propertyname,Selectivity as selectivity FROM %Dictionary.StoragePropertyDefinition WHERE parent %PATTERN '"_pattern_"'")
	if $$$ISERR(tSC) {
		W !,"Error prepare for Selectivty ",!
		Do DisplayError^%apiOBJ(tSC)
		quit
	}
	set tSC=rs.Execute()
	if $$$ISERR(tSC) {
		W !,"Error execute for Selectivty ",!
		Do DisplayError^%apiOBJ(tSC)
		quit
	}
	for {
		quit:'rs.Next(.tSC)
		continue:$$$ISERR(tSC)
		
		set classname=rs.Data("classname")
		set storage=rs.Data("storage")
		set propertyname=rs.Data("propertyname")
		set selectivity=rs.Data("selectivity")
		
		continue:classname=""
		set:storage="" storage="_"
		continue:propertyname=""
		set ^||SEL(classname,propertyname,storage)=selectivity
	}
	
	// Get the SQL name for the class
	set classname=""
	for {
		set classname=$Order(^||SEL(classname))
		quit:classname=""
		
		&SQL(SELECT %NOLOCK SqlTableName
			INTO :sqlTableName
			FROM %Dictionary.ClassDefinition
			WHERE NAME=:classname)
		if SQLCODE=0,$L(sqlTableName) {
			set ^||SEL(classname)=sqlTableName
		} else {
			set ^||SEL(classname)=$TR($P(classname,".",1,*-1),".","_")_"."_$P(classname,".",*)
		}
		
		// Get SQL Name for Property
		set propertyname=""
		for {
			set propertyname=$O(^||SEL(classname,propertyname))
			quit:propertyname=""
			
			&SQL(SELECT %NOLOCK SqlFieldName
				INTO :sqlFieldName
				FROM %Dictionary.PropertyDefinition
				WHERE parent=:classname
				AND NAME=:propertyname)
			if SQLCODE=0,$L(sqlTableName) {
				set ^||SEL(classname,propertyname)=sqlFieldName
			} else {
				set ^||SEL(classname,propertyname)=propertyname
			}
		}
		
		// Generate counts per field in record
		set rs=##class(%ResultSet).%New("%DynamicQuery:SQL")
		set tSC=rs.Prepare("SELECT * from "_$G(^||SEL(classname)))
		if $$$ISERR(tSC) {
			W !,"Error prepare for table ",$G(^||SEL(classname))," for class ",classname,!
			Do DisplayError^%apiOBJ(tSC)
			continue
		}
		set tSC=rs.Execute()
		if $$$ISERR(tSC) {
			W !,"Error execute for table ",$G(^||SEL(classname))," for class ",classname,!
			Do DisplayError^%apiOBJ(tSC)
			continue
		}
		for {
			quit:'rs.Next(.tSC)
			continue:$$$ISERR(tSC)
			
			// Make a count of the numer of records processed
			set x=$I(^||SELo(classname))
			
			set propertyname=""
			for {
				set propertyname=$O(^||SEL(classname,propertyname),1,sqlFieldName)
				quit:propertyname=""
				continue:sqlFieldName=""  // Not expected
				
				// Also traps null values with "_" literal
				set data="_"_$G(rs.Data(sqlFieldName))
				// create a hash for large values too large to use in count index
				set:$L(data)>21 data=$SYSTEM.Encryption.Base32Encode($SYSTEM.Encryption.SHA1Hash(data))
				
				// Create a counter of unique values
				set x=$I(^||SELo(classname,propertyname,data))
			}
		}
	}
	
	// Count distinct entries per property
	set classname=""
	for {
		set classname=$O(^||SELo(classname))
		quit:classname=""
		
		set propertyname=""
		for {
			set propertyname=$O(^||SELo(classname,propertyname))
			quit:propertyname=""
			
			set data="",count=0
			for {
				set data=$O(^||SELo(classname,propertyname,data))
				quit:data=""
				set count=count+1
			}
			set ^||SELo(classname,propertyname)=count
		}
	}
	
	// Output Report
	write !,"Classname,SQL_TableName,Property,SQL_FieldName,Code_Selectivity,RecordCount,Count_DistinctValues,Calculated_Selectivity"
	set classname=""
	for {
		set classname=$O(^||SEL(classname),1,sqlTableName)
		quit:classname=""
		
		set recordCount=+$G(^||SELo(classname))
		
		set propertyname=""
		for {
			set propertyname=$O(^||SEL(classname,propertyname),1,sqlFieldName)
			quit:propertyname=""
			
			set storage="",selectivity=""
			for {
				set storage=$O(^||SEL(classname,propertyname,storage),1,selectivity)
				quit:storage=""
				quit:selectivity'=""
			}
			
			set countDistinctValues=+$G(^||SELo(classname,propertyname))
			set calculatedSelectivity=""
			set:recordCount>0 calculatedSelectivity=$FN(100/countDistinctValues,,2)_"%"
		
			W !,classname,",",sqlTableName,",",propertyname,",",sqlFieldName,",",selectivity
			W ",",recordCount,",",countDistinctValues,",",calculatedSelectivity
		}	
	}
	// Tidy up
	kill ^||SEL,^||SELo
	Quit $$$OK
}

}

