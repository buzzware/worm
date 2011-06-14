package flexUnitTests {
	
	import au.com.buzzware.worm.Migration;
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

	public class MigrationTests {		
		
		[Before]
		public function setUp():void {
			Worm.reset();
			Worm.connect("worm-test.db");
			Worm.instance.dontExecuteSql = true
			Worm.instance.sqlCapture = []
			//Worm.addMigration(Migration_20100312_CreateTables);
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
		public function basicTableCreate(): void {
			var rs: RecordSet = Worm.instance.createTable(
				'thing',
				{
					id: int,
					name: String,
					type: String,
					length: int
				}
			)
			assertEquals(
				//"create table t1 (t1key INTEGER PRIMARY KEY,data TEXT,num double,timeEnter DATE);"
				'CREATE TABLE "thing" ("id" INTEGER PRIMARY KEY, "length" INTEGER, "name" STRING, "type" STRING)',
				Worm.instance.sqlCapture[0]
			)
		}

		[Test]
		public function basicMigration(): void {
			Worm.instance.addMigration(Migration_20100312_CreateTables)
			Worm.instance.migrate()
			assertEquals(2,Worm.instance.sqlCapture.length)
			assertEquals(				
				'CREATE TABLE "order" ("id" INTEGER PRIMARY KEY, "date" INTEGER, "description" STRING, "product_id" INTEGER)',
				Worm.instance.sqlCapture[0]
			)
			assertEquals(
				'CREATE TABLE "product" ("id" INTEGER PRIMARY KEY, "description" STRING, "price" REAL, "stock" INTEGER)',
				Worm.instance.sqlCapture[1]
			)
		}
	}	
}
