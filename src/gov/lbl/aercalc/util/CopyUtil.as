package gov.lbl.aercalc.util
{
	import mx.collections.ArrayCollection;
	import org.as3commons.reflect.Accessor;
	import org.as3commons.reflect.AccessorAccess;
	import org.as3commons.reflect.Type;
	import org.as3commons.reflect.Variable;

	public class CopyUtil
	{
		public function CopyUtil()
		{
		}
		
		public static function getClassName(object:Object):String
		{
			return Type.forInstance(object).name;
		}
		
		public static function clone(object:Object):Object
		{
			if(object == null){
				return null;
			}

			if (object is Array){
				return cloneArray(object as Array);
			}
			
			var objectClass:Class = Type.forInstance(object).clazz;
			var copy:Object = new objectClass();
			copyFrom(object, copy);
			return copy;
		}


		public static function cloneArray(array:Array):Array
		{
			if (array==null){
				return [];
			}
			var resultArr:Array = [];
			for each(var o:Object in array) {
				resultArr.push(clone(o));
			}
			return resultArr;
		}

		public static function copyFrom(source:Object, target:Object):void
		{
			var sourceInfo:Type = Type.forInstance(source);
			var propertyName:String;
			var value:Object;
			for each(var variableField:Variable in sourceInfo.variables)
			{
				if (!variableField.isStatic)
				{
					propertyName = variableField.name;
					value = source[propertyName];
					if(value is Array)
						target[propertyName] = cloneArray(value as Array);
					else if(value is ArrayCollection)
						target[propertyName] = new ArrayCollection(cloneArray((value as ArrayCollection).source));
					else
						target[propertyName] = value;
				}
			}
			for each(var accessorField:Accessor in sourceInfo.accessors)
			{
				if(accessorField.isStatic)
					continue;
				if (accessorField.access == AccessorAccess.READ_WRITE)
				{
					propertyName = accessorField.name;
					value = source[propertyName];
					if(value is Array)
						target[propertyName] = cloneArray(value as Array);
					else if(value is ArrayCollection)
						target[propertyName] = new ArrayCollection(cloneArray((value as ArrayCollection).source));
					else
						target[propertyName] = value;
				}
			}
		}
		
		private static function getDefaultValue(type:Type):Object
		{
			var res:Object;
			switch (type.clazz)
			{
				case String:
					res = "";
					break;
				case Number:
					res = 0.0;
					break;
				case int:
					res = 0;
					break;
				case Boolean:
					res = false;
					break;
				default:
					res = null;
					break;
			}
			return res;
		}
		
		private static function equals(item1:Object, item2:Object, clazz:Class):Boolean
		{
			var result:Boolean = item1 == item2;			
			return result;
		}
		
		public static function getProperties(source:Array):Object
		{
			var result:Object = CopyUtil.clone(source[0]);
			for (var i:int = 1; i < source.length; i++)
			{
				var element:Object = source[i];
				var sourceInfo:Type = Type.forInstance(element);
				var propertyName:String;
				for each(var variableField:Variable in sourceInfo.variables)
				{
					if (!variableField.isStatic)
					{
						propertyName = variableField.name;
						if (!equals(result[propertyName], element[propertyName], variableField.type.clazz))
						{
							result[propertyName] = getDefaultValue(variableField.type);
						}
					}
				}
				for each(var accessorField:Accessor in sourceInfo.accessors)
				{
					if (accessorField.access == AccessorAccess.READ_WRITE && !accessorField.isStatic)
					{
						propertyName = accessorField.name;
						if (!equals(result[propertyName], element[propertyName], accessorField.type.clazz))
						{
							result[propertyName] = getDefaultValue(accessorField.type);
						}
					}
				}
			}
			return result;
		}
		
	}
}