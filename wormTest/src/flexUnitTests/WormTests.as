package flexUnitTests {
	
	import au.com.buzzware.worm.RecordSet;
	import au.com.buzzware.worm.Worm;
	
	import flash.data.SQLConnection;
	import flash.data.SQLResult;
	import flash.data.SQLSchemaResult;
	import flash.data.SQLStatement;
	import flash.data.SQLTableSchema;
	import flash.errors.SQLError;
	import flash.filesystem.File;
	
	import mx.collections.ArrayCollection;
	import mx.collections.Sort;
	import mx.collections.SortField;
	
	import org.flexunit.asserts.assertEquals;
	import org.flexunit.asserts.assertNotNull;
	import org.flexunit.asserts.assertTrue;
	import org.hamcrest.assertThat;
	import org.hamcrest.object.equalTo;

	public class WormTests {		
		
		[Before]
		public function setUp():void {
			Worm.connect("worm-test.db");
		}
		
		[After]
		public function tearDown():void {
		}
		
		[BeforeClass]
		public static function setUpBeforeClass():void {
		}
		
		[AfterClass]
		public static function tearDownAfterClass():void {
		}
		
		[Test]
		public function basicInsertSql(): void {
			var rs: RecordSet = Worm.insert({
				first_name: "Fred",
				last_name: "Bear"
			}).into('person');
			assertEquals(
				"INSERT INTO \"person\" (\"first_name\",\"last_name\") VALUES ('Fred','Bear')",
				rs.prepareSql()
			)
		}

		[Test]
		public function basicSelectSql(): void {
			var rs: RecordSet = Worm.select().from('person');
			assertEquals(
				"SELECT * FROM \"person\"",
				rs.prepareSql()
			)
		}
		
		[Test]
		public function basicUpdateSql(): void {
			var rs: RecordSet = Worm.update('person').set({
				last_name: "Snake"
			})				
			assertEquals(
				"UPDATE \"person\" SET \"last_name\" = 'Snake'",
				rs.prepareSql()
			)
		}
		
		[Test]
		public function selectWithFieldsSql(): void {
			var rs: RecordSet
			rs = Worm.select('first_name').from('person');
			assertEquals(
				"SELECT \"first_name\" FROM \"person\"",
				rs.prepareSql()
			)
			rs = Worm.select('first_name,last_name').from('person');
			assertEquals(
				"SELECT first_name,last_name FROM \"person\"",
				rs.prepareSql()
			)
			rs = Worm.select(['first_name']).from('person');
			assertEquals(
				"SELECT \"first_name\" FROM \"person\"",
				rs.prepareSql()
			)
			rs = Worm.select(['first_name','last_name']).from('person');
			assertEquals(
				"SELECT \"first_name\",\"last_name\" FROM \"person\"",
				rs.prepareSql()
			)
			rs = Worm.select(['last_name','first_name']).from('person');
			assertEquals(
				"SELECT \"last_name\",\"first_name\" FROM \"person\"",
				rs.prepareSql()
			)
		}		
	}	
}
