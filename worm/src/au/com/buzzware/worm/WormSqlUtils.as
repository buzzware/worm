package au.com.buzzware.worm {
	import flash.utils.getQualifiedClassName;

import org.flexunit.internals.builders.NullBuilder;

public class WormSqlUtils {

		public static function fieldsToString(aFields: Array): String {
			var names: String
			for each (var f:String in aFields) {
				if (!names)
					names = '"'+f+'"'
				else
					names += ','+'"'+f+'"';
			}
			return names
		}
		
		public static function valueToSql(aValue: *): String {
			var cls: String = getQualifiedClassName(aValue)
			switch (cls) {
				case 'String': return "'"+aValue+"'"; break;
				case 'int':
				case 'Number':
					return aValue.toString(); break;
				case 'Boolean':
					return aValue ? '1' : '0'; break;
				case 'null':
					return 'NULL'; break;
				default:
					throw new Error("unsupported type "+cls);
			}
			return null;
		}
		
		// modifies the array
		public static function sortFieldNames(aFieldNames: Array): Array {
			aFieldNames = aFieldNames.sort()
			var ididx: int = aFieldNames.indexOf('id')
			if (ididx>=0) {
				aFieldNames.splice(ididx,1);
				aFieldNames.unshift('id')
			}
			return aFieldNames
		}
	}
}