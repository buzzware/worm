package au.com.buzzware.worm {
	import au.com.buzzware.actiontools4.code.ObjectAndArrayUtils;
	import au.com.buzzware.actiontools4.code.ReflectionUtils;
	
	import flash.data.SQLConnection;
	import flash.filesystem.File;
	

	public class Worm {
		
		public static const SQLTYPE_INTEGER:String = "INTEGER";		
		public static const SQLTYPE_REAL:String = "REAL";
		public static const SQLTYPE_DATE:String = "DATE";	// not actually supported by sqlite
		public static const SQLTYPE_BOOLEAN:String = "BOOLEAN";
		public static const SQLTYPE_TEXT:String = "TEXT";
		public static const SQLTYPE_STRING:String = "STRING";
		
		public var dontExecuteSql: Boolean = false
		public var sqlCapture: Array = []
		public var migrations: Array = []
		
		public function Worm() {
			
		}
		
		public static function reset(): void {
			_instance = null
		}
		
		protected static var _instance: Worm
		public static function get instance(): Worm {
			if (!_instance)
				_instance = new Worm();
			return _instance
		}
			
		protected var _connection: SQLConnection
		public function get connection(): SQLConnection {
			return _connection
		}

		public function connect(aFilename: String): SQLConnection  {
			var dbFile:File = File.applicationStorageDirectory.resolvePath(aFilename);
			_connection = new SQLConnection();
			_connection.open(dbFile);
			return _connection
		}
		
		public function executeSql(aSql: String): RecordSet {
			var result: RecordSet = new RecordSet();
			if (dontExecuteSql) {
				sqlCapture.push(aSql)
				return result 
			}
			return null
		}

		public function insertSql(aSql: String): RecordSet {
			var result: RecordSet = new RecordSet();
			result.insertSql(aSql);
			return result;
		}
		
		public function insert(aValues: *): RecordSet {
			var result: RecordSet = new RecordSet();
			result.insert(aValues);
			return result;
		}
		
		public function selectSql(aSql: String = null): RecordSet {
			var result: RecordSet = new RecordSet();
			result.selectSql(aSql);
			return result;
		}
		
		public function select(aFields: * = null): RecordSet {
			var result: RecordSet = new RecordSet();
			result.select(aFields);
			return result;
		}

		public function updateSql(aTable:String=null): RecordSet {
			var result: RecordSet = new RecordSet();
			result.updateSql(aTable);
			return result;
		}
		
		public function update(aTable:String=null): RecordSet {
			var result: RecordSet = new RecordSet();
			result.update(aTable);
			return result;
		}
		
		public function createTable(aTable: String, aFields: Object): RecordSet {
			var sql: String = 'CREATE TABLE "'+aTable+'" ('
			var fieldNames: Array = ReflectionUtils.getFieldNames(aFields)
			fieldNames = WormSqlUtils.sortFieldNames(fieldNames)
			var cols: Array = []
			for each (var n: String in fieldNames) {
				var t: String = '"'+n+'" ';
				var dt: * = aFields[n] 
				if (dt==int) {
						t += SQLTYPE_INTEGER;
						if (n=='id')
							t += ' PRIMARY KEY';
				} else if (dt==Number) {
					t += SQLTYPE_REAL
				} else if (dt==Date) {
					t += SQLTYPE_INTEGER
				} else if (dt==Boolean) {
					t += SQLTYPE_BOOLEAN
				} else if (dt==String) {
					t += SQLTYPE_STRING
				}
				cols.push(t)	
			}
			sql += cols.join(', ')
			sql += ')'
			return executeSql(sql)
		}
		
		public function addMigration(aMigration: Class): void {
			migrations.push(aMigration)
		}
		
		public function migrate(): void {
			for each (var c: Class in migrations) {
				var m: Migration = (new c()) as Migration
				m.dontExecuteSql = this.dontExecuteSql
				m.up();
				for each (var i: * in m.sqlCapture) {
					this.sqlCapture.push(i)	
				}
			}
		}
				
		// %%% Convenience static methods %%%
		
		public static function connect(aFilename: String): SQLConnection  {
			return instance.connect(aFilename)
		}
		
		public static function insertSql(aSql: String): RecordSet {
			return instance.insertSql(aSql);			
		}
		
		public static function insert(aValues: *): RecordSet {
			return instance.insert(aValues);			
		}
		
		public static function selectSql(aSql: String=null): RecordSet {
			return instance.selectSql(aSql);
		}
		
		public static function select(aFields: *=null): RecordSet {
			return instance.select(aFields);
		}
		
		public static function updateSql(aSql:String): RecordSet {
			return instance.updateSql(aSql);
		}
		
		public static function update(aTable: String): RecordSet {
			return instance.update(aTable);
		}
	}
}