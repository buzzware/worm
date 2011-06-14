package flexUnitTests {

	import au.com.buzzware.worm.Migration;
	import au.com.buzzware.worm.Worm;
	
	public class Migration_20100312_CreateTables extends Migration {
	
		override public function up(): void {
			createTable(
				'order',
				{
					id: int,
					description: String,
					product_id: int,
					date: Date
				}
			)

			createTable(
				'product',
				{
					id: int,
					description: String,
					price: Number,
					stock: int
				}
			)

		}
	}
}