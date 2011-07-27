package au.com.buzzware.worm {
import au.com.buzzware.actiontools4.code.ObjectAndArrayUtils;
import au.com.buzzware.actiontools4.code.ReflectionUtils;
import au.com.buzzware.actiontools4.code.StringUtils;

import flash.data.SQLConnection;
import flash.data.SQLResult;
import flash.data.SQLSchemaResult;
import flash.data.SQLStatement;
import flash.data.SQLTableSchema;
import flash.events.SQLErrorEvent;
import flash.events.SQLEvent;
import flash.filesystem.File;
import flash.utils.getQualifiedClassName;

public class Worm {

	public static const SQLTYPE_INTEGER:String = "INTEGER";
	public static const SQLTYPE_REAL:String = "REAL";
	public static const SQLTYPE_DATE:String = "DATE";	// not actually supported by sqlite
	public static const SQLTYPE_BOOLEAN:String = "BOOLEAN";
	public static const SQLTYPE_TEXT:String = "TEXT";
	public static const SQLTYPE_STRING:String = "STRING";

	// preserved base variables
	public var dontExecuteSql:Boolean = false
	public var sqlCapture:Array = []
	public var migrations:Array = []
	protected var _objectClassField: String = 'objectClass';  // name of field for storing class of object in typeless objects
	protected var _idField: String = 'id';  // name of field for storing class of object in typeless objects

	// variables cleared eg. by select
	protected var _dataClass: Class;

	protected var _command:String
	protected var _table:String
	protected var _select:String
	protected var _where:String
	protected var _join:String
	protected var _update:String
	protected var _values:String

	public var data:Array;

	public function Worm() {
		clear()
	}

	public static function reset():void {
		_instance = null
	}

	protected function clearData():void {
		data = new Array()
	}

	public function clear(): Worm {
		_dataClass = null

		_command = null
		_table = null
		_select = null
		_where = null
		_join = null
		_update = null
		_values = null
		clearData()
		return this
	}

	protected static var _instance:Worm
	public static function get instance():Worm {
		if (!_instance)
			_instance = new Worm();
		return _instance
	}

	protected var _connection:SQLConnection
	public function get connection():SQLConnection {
		return _connection
	}

	public function set connection(aValue:SQLConnection):void {
		_connection = aValue
	}

	public function connect(aFilename:String):SQLConnection {
		var dbFile:File = File.applicationStorageDirectory.resolvePath(aFilename);
		_connection = new SQLConnection();
		_connection.open(dbFile);
		return _connection
	}

	public function get objectClassField(): String {
		return _objectClassField
	}

	public function get idField(): String {
		return _idField
	}

	public function get idIsAutoIncrement(): Boolean {
		return true
	}

	protected function executeSqlInternal(aSql:String, aResultHandler:Function = null, aErrorHandler:Function = null):SQLResult {
		if (dontExecuteSql) {
			sqlCapture.push(aSql)
			return new SQLResult()
		}
		var st:SQLStatement = new SQLStatement();
		st.sqlConnection = _connection;
		st.text = aSql
		if (aResultHandler != null)
			st.addEventListener(SQLEvent.RESULT, aResultHandler);
		if (aErrorHandler != null)
			st.addEventListener(SQLErrorEvent.ERROR, aErrorHandler);
		//try {
		st.execute();
		//}
		//catch (error:SQLError) {
		//	trace("Error message:", error.message);
		//	trace("Details:", error.details);
		//}
		return st.getResult();
	}

	public function executeSql(aSql:String):Worm {
		var result:SQLResult = executeSqlInternal(aSql)
		fillFromSqlResult(result)
		return this
	}

	public function prepareSql():String {
		var strings:Array = new Array()
		strings.push(_command)
		if (_command == 'SELECT') {
			strings.push(_select)
		}
		if (_command == 'INSERT') {
			strings.push('INTO')
			strings.push(_table)
			strings.push(_values)
		}
		if (_command == 'SELECT') {
			strings.push('FROM')
			strings.push(_table)
		}
		if (_command == 'UPDATE') {
			strings.push(_update)
			strings.push('SET')
			strings.push(_values)
		}
		return strings.join(' ')
	}

	public function execute():Worm {
		var result:SQLResult
		var sql:String = prepareSql()

		if (_command=='INSERT') {
			executeSqlInternal(sql)
			result = executeSqlInternal('SELECT * from '+_table+' where ROWID=last_insert_rowid();')
		} else {
			result = executeSqlInternal(sql)
		}
		fillFromSqlResult(result)

		return this
	}

	protected function methodRequiresSqlExecute():void {
		execute()
	}

	protected function methodClearsSqlParameters():void {
		clear()
	}

	//
	// Helper Methods
	//

	private function tableFromObject(aValues:*):String {
		var klass:String = ReflectionUtils.getClassName(aValues)
		var result: String = StringUtils.snake_case(klass)
		return result
	}

	public function fillFromSqlResult(aSQLResult:SQLResult):void {
		clearData()
		if (!aSQLResult.data)
			return;
		for each (var i:Object in aSQLResult.data) {
			var newItem: *
			if (_dataClass) {
				newItem = new _dataClass()
				ReflectionUtils.copyAllFields(newItem,i)
			} else {
				newItem = i
			}
			data.push(newItem)
		}
	}


	//
	// SQL keyword methods
	//

	public function valuesSql(aValuesSql:String):Worm {
		_values = aValuesSql
		return this;
	}

/*
	var fields:Object = ReflectionUtils.getFieldsWithClassNames(aValueObject)
	var fieldNames:Array = ObjectAndArrayUtils.getDynamicPropertyNames(fields).sort()
	var arrValues:Array = new Array()
	for each (var f:String in fieldNames) {
		arrValues.push(WormSqlUtils.valueToSql(aValueObject[f]))
	}
	var sql:String = '(' + WormSqlUtils.fieldsToString(fieldNames) + ') VALUES (' + arrValues.join(',') + ')'
*/

	public function values(aValueObject:*):Worm {
		var fields:Object = ReflectionUtils.getFieldsWithClassNames(aValueObject)
		var fieldNames:Array = ObjectAndArrayUtils.getDynamicPropertyNames(fields).sort()
		ObjectAndArrayUtils.arrayRemove(fieldNames,objectClassField);
		if (idIsAutoIncrement)
			ObjectAndArrayUtils.arrayRemove(fieldNames,idField);
		var arrValues:Array = new Array()
		for each (var f:String in fieldNames) {
			arrValues.push(WormSqlUtils.valueToSql(aValueObject[f]))
		}
		var sql:String = '(' + WormSqlUtils.fieldsToString(fieldNames) + ') VALUES (' + arrValues.join(',') + ')'
		return valuesSql(sql);
	}

	public function into(aTable:String):Worm {
		_table = aTable
		if (_table.indexOf('"') == -1)
			_table = '"' + _table + '"';
		return this;
	}

	public function fromSql(aTables:String):Worm {
		_table = aTables
		return this;
	}

	public function from(aTables:*):Worm {
		if (aTables is String) {
			var t:String = aTables as String
			if (t.indexOf(',') == -1)	// just single table name
				t = '"' + t + '"';
			return fromSql(t);
		} else if (aTables is Array) {
			return fromSql(WormSqlUtils.fieldsToString(aTables as Array));
		} else if (aTables is Class) {
			asClass(aTables)
			return fromSql(tableFromObject(aTables));
		}
		else
			throw new Error('unsupported type ' + getQualifiedClassName(aTables));
		return this
	}

	//
	// SQL Command methods
	//

	public function insertSql(aTable:String):Worm {
		_command = 'INSERT'
		_table = aTable
		return this;
	}

	// eg. (firstName,lastName) VALUES ('Fred','Bear')
	public function insert(aValueObject:*, aOptions:Object = null):Worm {
		values(aValueObject)
		var table:String = tableFromObject(aValueObject)
		_dataClass = ReflectionUtils.getClass(aValueObject)
		return insertSql(table)
	}

	public function selectSql(aSql:String = null):Worm {
		methodClearsSqlParameters()
		_command = 'SELECT'
		_select = (aSql ? aSql : '*')
		return this;
	}

	public function select(aFields:* = null):Worm {
		if (!aFields)
			return selectSql();
		if (aFields is String) {
			var t:String = aFields as String
			if (t.indexOf(',') == -1)	// just single table name
				t = '"' + t + '"';
			return selectSql(t);
		} else if (aFields is Array)
			return selectSql(WormSqlUtils.fieldsToString(aFields as Array));
		else
			throw new Error('unsupported type ' + getQualifiedClassName(aFields));
	}

	public function updateSql(aTable:String = null):Worm {
		_command = 'UPDATE'
		_update = aTable
		return this
	}

	public function update(aTable:String = null):Worm {
		if (aTable.indexOf('"') == -1)
			aTable = '"' + aTable + '"';
		return updateSql(aTable)
	}


	//
	// Database-wide methods
	//

	/*
	 statement.sqlConnection.open(store, SQLMode.READ);
	 // use SQLTableSchema to get tables only,
	 // see the loadSchema API Doc
	 statement.sqlConnection.loadSchema();

	 var result:SQLSchemaResult = statement.sqlConnection.getSchemaResult();
	 for each (var table:SQLTableSchema in result.tables)
	 {
	 trace(table.name);
	 }
	 */

	public function get tables():Array {
		var result:Array = []
		connection.loadSchema(SQLTableSchema, null, "main", false) //SQLTableSchema,null,null,false)
		var r:SQLSchemaResult = connection.getSchemaResult()
		for each (var table:SQLTableSchema in r.tables) {
			result.push(table.name)
		}
		return result;
	}


	//
	// Object methods
	//

	public function get first():* {
		methodRequiresSqlExecute()
		return data ? data[0] : null
	}

	public function get last():* {
		methodRequiresSqlExecute()
		return data ? data[data.length - 1] : null
	}

	public function asClass(aType: Class): Worm {
		_dataClass = aType
		return this
	}

	// aType: SomeVOClass or Object or DynamicObject or
	public function to(aType:*):Worm {
		if (!data)
			return this;
		var newData:Array = []
		for each (var i:* in data) {
			var obj:Object = new aType()
			ObjectAndArrayUtils.copy_properties(obj, i)
			newData.push(obj)
		}
		return this
	}

	// may not seem necessary, but is nicer than .execute().data
	public function toArray():Array {
		methodRequiresSqlExecute()
		return data
	}

	public function toSimpleArray(aProperty: String = null):Array {
		if (!aProperty) {
			var fields: Array = getDataFields(data[0])
			aProperty = fields[0]
		}
		return ObjectAndArrayUtils.ObjectArrayExtractPropertyValues(data, aProperty)
	}

	public function getDataFields(aDataItem:*):Array {
    var fieldNames: Array = ReflectionUtils.getFieldNames(aDataItem).sort()
		ObjectAndArrayUtils.arrayRemove(fieldNames,objectClassField);
		if (idIsAutoIncrement)
			ObjectAndArrayUtils.arrayRemove(fieldNames,idField);
		return fieldNames
	}

	//
	// Migrations
	//

	public function createTable(aTable:String, aFields:Object):Worm {
		var sql:String = 'CREATE TABLE "' + aTable + '" ('
		var fieldNames:Array = ReflectionUtils.getFieldNames(aFields)
		fieldNames = WormSqlUtils.sortFieldNames(fieldNames)
		var cols:Array = []
		for each (var n:String in fieldNames) {
			var t:String = '"' + n + '" ';
			var dt:* = aFields[n]
			if (dt == int) {
				t += SQLTYPE_INTEGER;
				if (n == 'id')
					t += ' PRIMARY KEY';
			} else if (dt == Number) {
				t += SQLTYPE_REAL
			} else if (dt == Date) {
				t += SQLTYPE_INTEGER
			} else if (dt == Boolean) {
				t += SQLTYPE_BOOLEAN
			} else if (dt == String) {
				t += SQLTYPE_STRING
			}
			cols.push(t)
		}
		sql += cols.join(', ')
		sql += ')'
		return executeSql(sql)
	}

	public function addMigration(aMigration:Class):void {
		migrations.push(aMigration)
	}

	public function migrate():void {
		for each (var c:Class in migrations) {
			var m:Migration = (new c()) as Migration
			m.dontExecuteSql = this.dontExecuteSql
			m.connection = this.connection
			m.up();
			for each (var i:* in m.sqlCapture) {
				this.sqlCapture.push(i)
			}
		}
	}


	//
	// Convenience static methods
	//

	/*
	 public static function connect(aFilename: String): SQLConnection  {
	 return instance.connect(aFilename)
	 }

	 public static function insertSql(aTable: String, aSql: String): Worm {
	 return instance.insertSql(aTable, aSql);
	 }

	 public static function insert(aValues: *): Worm {
	 return instance.insert(aValues);
	 }

	 public static function selectSql(aSql: String=null): Worm {
	 return instance.selectSql(aSql);
	 }

	 public static function select(aFields: *=null): Worm {
	 return instance.select(aFields);
	 }

	 public static function updateSql(aSql:String): Worm {
	 return instance.updateSql(aSql);
	 }

	 public static function update(aTable: String): Worm {
	 return instance.update(aTable);
	 }
	 */
}
}