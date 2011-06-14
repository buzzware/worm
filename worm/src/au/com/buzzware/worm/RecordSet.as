package au.com.buzzware.worm {
	
	import au.com.buzzware.actiontools4.code.ObjectAndArrayUtils;
	import au.com.buzzware.actiontools4.code.ReflectionUtils;
	
	import flash.utils.getQualifiedClassName;

	public class RecordSet {
		
		public var worm: Worm
		
		protected var _command: String
		protected var _select: String
		protected var _from: String
		protected var _into: String
		protected var _where: String
		protected var _join: String	
		protected var _insertValues: String
		protected var _update: String
		protected var _set: String

		public function RecordSet() {
		}

		public function insertSql(aValuesSql: String): RecordSet {
			_command = 'INSERT'
			_insertValues = aValuesSql
			return this;
		}
		
		// eg. (firstName,lastName) VALUES ('Fred','Bear')
		public function insert(aValues: *): RecordSet {
			var fields: Object = ReflectionUtils.getFieldsWithClassNames(aValues)
			var fieldNames: Array = ObjectAndArrayUtils.getDynamicPropertyNames(fields).sort()
			var arrValues: Array = new Array()			
			for each (var f:String in fieldNames) {
				arrValues.push(WormSqlUtils.valueToSql(aValues[f]))
			}
			var sql: String = '('+WormSqlUtils.fieldsToString(fieldNames)+') VALUES ('+arrValues.join(',')+')' 
			return insertSql(sql);
		}
		
		public function selectSql(aSql: String = null): RecordSet {
			_command = 'SELECT'
			_select = (aSql ? aSql : '*')
			return this;
		}
		
		public function select(aFields: * = null): RecordSet {
			if (!aFields)
				return selectSql();
			if (aFields is String) {
				var t: String = aFields as String
				if (t.indexOf(',')==-1)	// just single table name
					t = '"'+t+'"';
				return selectSql(t);
			} else if (aFields is Array)
				return selectSql(WormSqlUtils.fieldsToString(aFields as Array));
			else
				throw new Error('unsupported type '+getQualifiedClassName(aFields));
		}

		public function updateSql(aTable:String=null): RecordSet {
			_command = 'UPDATE'
			_update = aTable
			return this
		}
		
		public function update(aTable:String=null): RecordSet {
			if (aTable.indexOf('"')==-1)
				aTable = '"'+aTable+'"';			
			return updateSql(aTable)
		}		

		public function setSql(aValuesSql:String): RecordSet {
			_set = aValuesSql
			return this;
		}		
		
		public function set(aValues: *): RecordSet {
			var sql: String
			var fields: Object = ReflectionUtils.getFieldsWithClassNames(aValues)
			var fieldNames: Array = ObjectAndArrayUtils.getDynamicPropertyNames(fields).sort()
			var arrValues: Array = new Array()
			
			for each (var f:String in fieldNames) {
				var s: String = '"'+f+'" = '+WormSqlUtils.valueToSql(aValues[f])
				if (!sql)
					sql = s;
				else
					sql += ', '+s;
			}
			return setSql(sql);
		}
		
		
		public function into(aTable: String): RecordSet {
			_into = aTable
			if (_into.indexOf('"')==-1)
				_into = '"'+_into+'"';
			return this;
		}
		
		public function fromSql(aTables: String): RecordSet {
			_from = aTables
			return this;
		}
		
		
		public function from(aTables: *): RecordSet {
			if (aTables is String) {
				var t: String = aTables as String
				if (t.indexOf(',')==-1)	// just single table name
					t = '"'+t+'"';
				return fromSql(t);
			} else if (aTables is Array)
				return fromSql(WormSqlUtils.fieldsToString(aTables as Array));
			else
				throw new Error('unsupported type '+getQualifiedClassName(aTables));
		}
		
		public function prepareSql(): String {
			var strings: Array = new Array()
			strings.push(_command)
			if (_command=='SELECT') {
				strings.push(_select)
			}
			if (_command=='INSERT') {
				strings.push('INTO')
				strings.push(_into)
				strings.push(_insertValues)
			}
			if (_command=='SELECT') {
				strings.push('FROM')
				strings.push(_from)
			}
			if (_command=='UPDATE') {
				strings.push(_update)
				strings.push('SET')
				strings.push(_set)
			}
			return strings.join(' ')
		}
		
		/*		
		public function updateSql(aSql: String): RecordSet {
		_command = 'SELECT'
		_select = aSql
		return this;
		}

		public function deleteSql(aSql: String): RecordSet {
			_command = 'SELECT'
			_select = aSql
			return this;
		}
		*/
	}
}