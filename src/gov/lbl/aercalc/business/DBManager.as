package gov.lbl.aercalc.business
{

	import flash.data.SQLConnection;
	import flash.data.SQLResult;
	import flash.data.SQLSchemaResult;
	import flash.data.SQLStatement;
	import flash.data.SQLTableSchema;
import flash.events.Event;
import flash.events.EventDispatcher;
import flash.events.IEventDispatcher;
import flash.events.SQLErrorEvent;
	import flash.events.SQLEvent;
	import flash.filesystem.File;
	import flash.utils.describeType;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;

import mx.collections.ArrayCollection;

import mx.controls.Alert;
	
	import gov.lbl.aercalc.model.ApplicationModel;
	import gov.lbl.aercalc.util.Logger;

	
	/** 
	 *  DBMANGER FOR AIR
	 * 
	 *  DBManager is a singleton that manages all connections and 
	 *  operations on the AERCalc DB. It also acts as an ORM for certain Classes.
	 *
	 * 	Some code adapted from: http://coenraets.org/blog/2008/12/using-the-sqlite-database-access-api-in-air%E2%80%A6-part-3-annotation-based-orm-framework/
	 * 
	 */
	
	public class DBManager extends EventDispatcher
	{

		public static var DB_CONNECTION_ERROR:String = "gov.lbl.aercalc.dbManager.db_connection_error";
		public static var DB_CONNECTION_OPENED:String = "gov.lbl.aercalc.dbManager.db_connection_opened";

		protected var _dbPath:String;
        protected var _dbFile:File;

		protected var _map:Object = {};
		protected var _sqlConnection:SQLConnection;

		
		protected var getDBVersionStmt:SQLStatement;
		protected var setDBVersionStmt:SQLStatement;


		public function DBManager()
		{
		}


		public function setDBFile(dbFile:File):void{
			if (!dbFile.exists){
				throw new Error("File does not exist: " + dbFile);
			}
			if (dbFile.extension!="sqlite"){
				throw new Error("Invalid extensions. Database files should have a .sqlite extensions");
			}
			_dbFile = dbFile;
			_dbPath = dbFile.nativePath;
		}


		public function closeSQLConnection():void {
            if (sqlConnection.connected) {
				sqlConnection.close();
                sqlConnection.removeEventListener(SQLEvent.OPEN, onConnectionOpen);
                sqlConnection.removeEventListener(SQLErrorEvent.ERROR, onConnectionError);
				sqlConnection = null;
			}
		}

		public function clear():void {
			this._dbFile = null;
			this._dbPath = null;
			this._map = {};
			if(sqlConnection){
                closeSQLConnection();
			}
			this.sqlConnection = null;
		}

		
		public function get isConnected():Boolean
		{
			if (sqlConnection)
			{
				return sqlConnection.connected;
			}
			return false;
		}
		
		
		public function get dbPath():String
		{
			return _dbPath;
		}
		public function set dbPath(value:String):void
		{
			if (sqlConnection.connected)
			{
				throw new Error("Can't change dbPath after sqlConnection has been made");
			}
            _dbPath = value;
		}
		
		
		public function openDB():void
		{
			_dbFile	= File.userDirectory.resolvePath(_dbPath);
			
			Logger.debug("openDB() dbPath: " + _dbPath, this);
			
			if (!_dbFile.exists)
			{
				throw new Error("DB File doesn't exist at path: " + _dbFile.nativePath);
			}			
			sqlConnection = new SQLConnection();
			sqlConnection.addEventListener(SQLEvent.OPEN, onConnectionOpen);
			sqlConnection.addEventListener(SQLErrorEvent.ERROR, onConnectionError);
			sqlConnection.open(_dbFile);

		}


		public function compact():void
		{		
			sqlConnection.compact();
		}


		public function findByID(c:Class, id:Number):Object
		{
			if (id==0) throw new Error("ID cannot be 0");
			
			if (!_map[c]) loadMetadata(c);
			var stmt:SQLStatement = _map[c].findStmt;
			var identity:Object = _map[c].identity;
			
			stmt.parameters[":id"] = id;
			stmt.execute();
			var result:Object = stmt.getResult().data;
			if (result==null) return null;
			var o:Object = typeObject(result[0],c);
			return o;
		}


		public function findByName(c:Class, name:String):Object
		{
			if (name=="") throw new Error("Name cannot be empty");
			
			if (!_map[c]) loadMetadata(c);
			var stmt:SQLStatement = _map[c].findByNameStmt;
			var identity:Object = _map[c].identity;
			
			stmt.parameters[":name"] = name;
			stmt.execute();
			
			// Return array typed objects
			var result:Array = stmt.getResult().data;
			if (result==null) return new ArrayCollection();
			return typeArray(result, c);
			
		}

		
		public function findFirstByName(c:Class, name:String):Object
		{
			if (name=="") throw new Error("Name cannot be empty");
			
			if (!_map[c]) loadMetadata(c);
			var stmt:SQLStatement = _map[c].findByNameStmt;
			var identity:Object = _map[c].identity;
			
			stmt.parameters[":name"] = name;
			stmt.execute();
			
			// Return first typed object in results
			var o:Object = stmt.getResult().data;
			if (o==null) return null;
			return typeObject(o[0],c);
		}
		
		
		public function findByForeignKey(c:Class, foreignKeyColumnName:String, foreignKeyID:int):ArrayCollection
		{
			if (foreignKeyColumnName=="") throw new Error("foreignKeyColumnName cannot be empty");
			if (foreignKeyID<1) throw new Error("foreignKey must be greater than 0");
			
			if (!_map[c]) loadMetadata(c);
			
			var tableName:String = _map[c].table;
			var stmt:SQLStatement = new SQLStatement();
			stmt.sqlConnection = sqlConnection;
			stmt.text = "SELECT * FROM "+tableName +" WHERE " + foreignKeyColumnName +"=:foreignKeyID";
			stmt.parameters[":foreignKeyID"] = foreignKeyID;
			
			stmt.execute();
			
			var result:Array = stmt.getResult().data;
			if (result==null) return null;
			return typeArray(result, c);
		}

		
		public function findFirst(c:Class):Object
		{
			//Logger.info("#DBM: findFirst c:" + c)
			// If not yet done, load the metadata for this class
			if (!_map[c]) loadMetadata(c);
			var stmt:SQLStatement = _map[c].findFirstStmt;
			stmt.execute();
			// Return typed object
			var o:Object = stmt.getResult().data;
			if (o==null) return null;
			return typeObject(o[0],c);
		}

		
		public function findAll(c:Class):ArrayCollection
		{
			// If not yet done, load the metadata for this class
			if (!_map[c]) loadMetadata(c);
			var stmt:SQLStatement = _map[c].findAllStmt;
			stmt.execute();
			// Return typed objects
			var result:Array = stmt.getResult().data;
			if (result==null) return new ArrayCollection();
			return typeArray(result, c);
		}
		
		
		/** @returns id of object saved */
		
		public function save(o:Object, createWithID:int=0):int
		{	
			//Logger.debug("save() o: " + o + " createWithID :" + createWithID, this)
			var c:Class = Class(getDefinitionByName(getQualifiedClassName(o)));
			var objectID:int //id of object being saved
			
			// If not yet done, load the metadata for this class
			if (!_map[c]) loadMetadata(c);
			var identity:Object = _map[c].identity;
			// Check if the object has an identity
			try
			{
				if (createWithID>0)
				{
					objectID = createItem(o,c, createWithID)	
				}				
				else if (o[identity.field]!=undefined && o[identity.field]>0)
				{
					// If yes, we deal with an update
					updateItem(o,c);
					objectID = o.id
				}
				else
				{
					// If no, this is a new item
					objectID = createItem(o,c);
				}

				// If object has an 'isDirty' property set it back to false
				if (o.hasOwnProperty("isDirty")&& o.isDirty){
					o.isDirty = false;
				}

				return objectID
			}
			catch(err:Error)
			{
				//if database locked, just show Alert
				if (err.errorID == 3119)
				{
					Alert.show("Database is locked. Please unlock and try again.")
					return 0
				}
				throw err
			}
			return 0
		}


		public function remove(o:Object):void
		{
			var c:Class = Class(getDefinitionByName(getQualifiedClassName(o)));
			// If not yet done, load the metadata for this class
			if (!_map[c]) loadMetadata(c);
			var identity:Object = _map[c].identity;
			var stmt:SQLStatement = _map[c].deleteStmt;
			stmt.parameters[":"+identity.field] = o[identity.field];
			stmt.execute()
		}

		
		public function removeByName(o:Object, name:String):void
		{
			var c:Class = Class(getDefinitionByName(getQualifiedClassName(o)));
			// If not yet done, load the metadata for this class
			if (!_map[c]) loadMetadata(c);
			var stmt:SQLStatement = _map[c].deleteByNameStmt;
			stmt.parameters[":name"] = name;
			stmt.execute();
		}


		public function removeByID(o:Object, id:int):void
		{
			var c:Class = Class(getDefinitionByName(getQualifiedClassName(o)));
			// If not yet done, load the metadata for this class
			if (!_map[c]) loadMetadata(c);
			var stmt:SQLStatement = _map[c].deleteByID;
			stmt.parameters[":id"] = id;
			try
			{
				stmt.execute();
			}
			catch(err:Error)
			{
				Logger.error("Couldn't removeByID() class: " + c.toString() + " id:" + id,this);
			}
		}
		
		
		protected function setupSQLCommands():void
		{
			getDBVersionStmt = new SQLStatement();
			getDBVersionStmt.sqlConnection = sqlConnection;
			getDBVersionStmt.text = "SELECT version FROM main.schema_migrations ORDER BY version DESC limit 1"; //get most recent version
			
			setDBVersionStmt = new SQLStatement();
			setDBVersionStmt.sqlConnection = sqlConnection;
			setDBVersionStmt.text = "INSERT INTO main.schema_migrations (version) values (:version)";//set most recent version
		}
		

		protected function onConnectionOpen(event:SQLEvent):void
		{
			setupSQLCommands();
            dispatchEvent(new Event(DBManager.DB_CONNECTION_OPENED));
		}

		
		protected function onConnectionError(event:SQLErrorEvent):void
		{
			Logger.error("onConnectionError(): Couldn't open connection " + event.toString(), this);
            dispatchEvent(new Event(DBManager.DB_CONNECTION_ERROR));
		}


		protected function createItem(o:Object, c:Class, createWithID:int = 0):int
		{
			//Logger.debug("createItem() class: " + c, this)
			
			var stmt:SQLStatement;
			
			if (createWithID>0)
			{
				stmt = _map[c].insertWithIDStmt;
				stmt.parameters[":id"] = createWithID;
			}	
			else
			{
				stmt = _map[c].insertStmt	
			}		
			
			var identity:Object = _map[c].identity;
			var fields:ArrayCollection = _map[c].fields;
			for (var i:int = 0; i<fields.length; i++)
			{
				var field:String = fields.getItemAt(i).field;
				if (field != identity.field)
				{
					stmt.parameters[":" + field] = o[field];
				}
			}
			stmt.execute()
			o[identity.field] = stmt.getResult().lastInsertRowID;
			return o[identity.field];
		}


		protected function updateItem(o:Object, c:Class):void
		{
			var stmt:SQLStatement = _map[c].updateStmt;
			var fields:ArrayCollection = _map[c].fields;
			for (var i:int = 0; i<fields.length; i++)
			{
				var field:String = fields.getItemAt(i).field;
				stmt.parameters[":" + field] = o[field];
			}
			stmt.execute();
		}


		protected function loadMetadata(c:Class):void
		{			
			_map[c] = new Object();
			var xml:XML = describeType(new c());
			var table:String = xml.metadata.(@name=="Table").arg.(@key=="name").@value;
			_map[c].table = table;
			_map[c].fields = new ArrayCollection();
			var variables:XMLList = xml.accessor;
			
			var insertParams:String = "";
			var updateSQL:String = "UPDATE " + table + " SET ";
			var insertSQL:String = "INSERT INTO " + table + " (";
			var insertWithIDSQL:String = "INSERT INTO " + table + "(id,";
			
			for (var i:int = 0 ; i < variables.length() ; i++) 
			{
				var field:String = variables[i].@name.toString();
				var column:String;
				//skip if labeled with Transient metadata
				if (variables[i].metadata.(@name=="Transient").length()>0)
				{
					continue;
				}				            	
				if (variables[i].metadata.(@name=="Column").length()>0)
				{
					column = variables[i].metadata.(@name=="Column").arg.(@key=="name").@value.toString(); 
				} 
				else
				{
					if (field.indexOf("_")==0)
					{
						column = field.slice(1);
					}
					else
					{
						column = field;					
					}
				}
				_map[c].fields.addItem({field: field, column: column});
				
				if (variables[i].metadata.(@name=="Id").length()>0)
				{
					_map[c].identity = {field: field, column: column};
				}
				else            	
				{
					insertSQL += column + ",";
					insertWithIDSQL += column + ",";
					insertParams += ":" + field + ",";
					updateSQL += column + "=:" + field + ",";	
				}
				
			}
			
			insertSQL = insertSQL.substring(0, insertSQL.length-1) + ") VALUES (" + insertParams;
			insertSQL = insertSQL.substring(0, insertSQL.length-1) + ")";
			
			insertWithIDSQL = insertWithIDSQL.substring(0, insertWithIDSQL.length-1) + ") VALUES (:id," + insertParams;
			insertWithIDSQL = insertWithIDSQL.substring(0, insertWithIDSQL.length-1) + ")";
			
			updateSQL = updateSQL.substring(0, updateSQL.length-1);
			
			if (_map[c].identity==null)
			{
				throw new Error("identity doesn't exist for class " + c);
			}
			
			var colName:String = _map[c].identity.column;
			var fieldName:String = _map[c].identity.field;
			updateSQL += " WHERE " + colName + "=:" + fieldName;
			
			
			var deleteSQL:String = "DELETE FROM main." + table + " WHERE " + _map[c].identity.column + "=:" + _map[c].identity.field;
			var deleteByNameSQL:String = "DELETE FROM main." + table + " WHERE name=:name";
			var deleteByID:String = "DELETE FROM main." + table + " WHERE id=:id";
			var findSQL:String = "SELECT * FROM main." + table + " WHERE id=:" + _map[c].identity.field;
			var findByNameSQL:String = "SELECT * FROM main." + table + " WHERE name=:name";
			var findFirstSQL:String = "SELECT * FROM main." + table + " LIMIT 1";
			var findByForeignKeySQL:String = "SELECT * FROM main." + table + " WHERE :foreignKeyColumnName=:foreignKeyID";
			
			var stmt:SQLStatement = new SQLStatement();
			stmt.sqlConnection = sqlConnection;
			stmt.text = insertSQL;
			_map[c].insertStmt = stmt;
			
			stmt = new SQLStatement();
			stmt.sqlConnection = sqlConnection;
			stmt.text = insertWithIDSQL;
			_map[c].insertWithIDStmt = stmt;
			
			stmt = new SQLStatement();
			stmt.sqlConnection = sqlConnection;
			stmt.text = updateSQL;
			_map[c].updateStmt = stmt;
			
			stmt = new SQLStatement();
			stmt.sqlConnection = sqlConnection;
			stmt.text = deleteSQL;
			_map[c].deleteStmt = stmt;
			
			stmt = new SQLStatement();
			stmt.sqlConnection = sqlConnection;
			stmt.text = deleteByNameSQL;
			_map[c].deleteByNameStmt = stmt;
			
			stmt = new SQLStatement();
			stmt.sqlConnection = sqlConnection;
			stmt.text = "SELECT * FROM " + table;
			_map[c].findAllStmt = stmt;
			
			stmt = new SQLStatement();
			stmt.sqlConnection = sqlConnection;
			stmt.text = findSQL;
			_map[c].findStmt = stmt;
			
			stmt = new SQLStatement();
			stmt.sqlConnection = sqlConnection;
			stmt.text = findByNameSQL;
			_map[c].findByNameStmt = stmt;
			
			stmt = new SQLStatement();
			stmt.sqlConnection = sqlConnection;
			stmt.text = findFirstSQL;
			_map[c].findFirstStmt = stmt;
			
			stmt = new SQLStatement();
			stmt.sqlConnection = sqlConnection;
			stmt.text = findByForeignKeySQL;
			_map[c].findByForeignKeyStmt = stmt;
			
		}


		protected function typeArray(a:Array, c:Class):ArrayCollection
		{
			if (a==null) return null;
			if (!_map[c]) loadMetadata(c);
			var ac:ArrayCollection = new ArrayCollection();
			var len:int = a.length
			for (var i:int=0; i<len; i++)
			{
				ac.addItem(typeObject(a[i],c));
			}
			return ac;			
		}


		protected function typeObject(o:Object, c:Class):Object
		{
			var instance:Object = new c();
			var fields:ArrayCollection = _map[c].fields;
			
			var len:int = fields.length
			for (var i:int; i<len; i++)
			{
				var item:Object = fields.getItemAt(i);
				instance[item.field] = o[item.column];	
			}
			return instance;
		}


		protected function getSQLType(asType:String):String
		{
			Logger.debug("astype: " + asType);
			if (asType == "int" || asType == "uint")
				return "INTEGER";
			else if (asType == "Number")
				return "REAL";
			else if (asType == "flash.utils::ByteArray")
				return "BLOB";
			else if (asType == "date")
				return "DATE";
			else
				return "TEXT";				
		}
		
		public function set sqlConnection(sqlConnection:SQLConnection):void
		{
			_sqlConnection = sqlConnection;
		}
		public function get sqlConnection():SQLConnection
		{
			if (!_sqlConnection)
			{
				_dbFile = File.userDirectory.resolvePath(_dbPath);
				_sqlConnection = new SQLConnection(); 
			}
			return _sqlConnection;
		}


		/* DB version is the most recent entry for the version column 
		in the schema_migrations table */
		public function getDBVersion():Number
		{		
			try
			{
				getDBVersionStmt.execute();
				var result:Array = getDBVersionStmt.getResult().data
				return result[0].version
			}
			catch(err:Error)
			{
				Logger.error("getDBVersion() couldn't get db version. Error:  "+ err, this)
				
			}
			return NaN
		}
		
		
		public function setDBVersion(version:Number):void
		{
			
			if (isNaN(version))
			{
				Logger.error("setDBVersion() version is NaN", this);
				return;
			}
			
			try
			{
				setDBVersionStmt.parameters[":version"] = version;
				setDBVersionStmt.execute();
			}
			catch(err:Error)
			{
				Logger.error("setDBVersion() couldn't set db version to: " + version+ " Error:  "+ err, this);
			}
		}
		

		public function traceTableNames():void
		{
			// use SQLTableSchema to get tables only,
			// see the loadSchema API Doc
			this.sqlConnection.loadSchema(); 			
			var result:SQLSchemaResult = sqlConnection.getSchemaResult();
			for each (var table:SQLTableSchema in result.tables)
			{
				Logger.debug("table name: " + table.name, this);
			} 
		}
	}
}