//
//	 ______    ______    ______    
//	/\  __ \  /\  ___\  /\  ___\   
//	\ \  __<  \ \  __\_ \ \  __\_ 
//	 \ \_____\ \ \_____\ \ \_____\ 
//	  \/_____/  \/_____/  \/_____/ 
//
//	Copyright (c) 2012 BEE creators
//	http://www.whatsbug.com
//
//	Permission is hereby granted, free of charge, to any person obtaining a
//	copy of this software and associated documentation files (the "Software"),
//	to deal in the Software without restriction, including without limitation
//	the rights to use, copy, modify, merge, publish, distribute, sublicense,
//	and/or sell copies of the Software, and to permit persons to whom the
//	Software is furnished to do so, subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in
//	all copies or substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//	FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
//	IN THE SOFTWARE.
//
//
//  Bee_ActiveRecord.h
//

#import "Bee_Precompile.h"
#import "Bee_Log.h"
#import "Bee_Runtime.h"
#import "Bee_UnitTest.h"

#import "NSObject+BeeTypeConversion.h"
#import "NSDictionary+BeeExtension.h"
#import "NSNumber+BeeExtension.h"

#import "Bee_Database.h"
#import "Bee_ActiveBase.h"
#import "Bee_ActiveRecord.h"

#import "JSONKit.h"

#include <objc/runtime.h>

#pragma mark -

#undef	__USE_ID_AS_KEY__
#define __USE_ID_AS_KEY__	(1)

#pragma mark -

@interface BeeActiveRecord()
- (void)initSelf;
- (void)setObservers;
- (void)setPropertiesFrom:(NSDictionary *)dict;
+ (void)setAssociateConditions;
@end

#pragma mark -

@implementation BeeActiveRecord

@dynamic EXISTS;
@dynamic LOAD;
@dynamic SAVE;
@dynamic INSERT;
@dynamic UPDATE;
@dynamic DELETE;

@synthesize changed = _changed;
@synthesize deleted = _deleted;

@dynamic JSON;
@dynamic JSONData;
@dynamic JSONString;

+ (BeeDatabase *)DB
{
	[self prepareOnceWithRootClass:[BeeActiveRecord class]];

	return super.DB.CLASS_TYPE( self );
}

+ (NSString *)activePrimaryKeyFor:(Class)clazz
{
	NSString * key = [super activePrimaryKeyFor:clazz];
	if ( nil == key )
	{
		key = @"id";
	}

	return key;
}

+ (NSString *)activeJSONKeyFor:(Class)clazz
{
	NSString * key = [super activeJSONKeyFor:clazz];
	if ( nil == key )
	{
		key = @"JSON";
	}

	return key;
}

+ (void)mapRelation
{
	for ( Class clazzType = self;; )
	{		
		NSUInteger			propertyCount = 0;
		objc_property_t *	properties = class_copyPropertyList( clazzType, &propertyCount );
		
		for ( NSUInteger i = 0; i < propertyCount; i++ )
		{
			const char *	name = property_getName(properties[i]);
			NSString *		propertyName = [NSString stringWithCString:name encoding:NSUTF8StringEncoding];
			
			const char *	attr = property_getAttributes(properties[i]);
			NSUInteger		type = [BeeTypeEncoding typeOf:attr];
			
			NSObject *		defaultValue = nil;
			
			if ( BeeTypeEncoding.NSNUMBER == type )
			{
				defaultValue = __INT(0);
			}
			else if ( BeeTypeEncoding.NSSTRING == type )
			{
				defaultValue = @"";
			}
			else if ( BeeTypeEncoding.NSDATE == type )
			{
				defaultValue = [NSDate dateWithTimeIntervalSince1970:0];
			}
			else
			{
				defaultValue = @"";
			}
			
			if ( NSOrderedSame == [propertyName compare:@"id" options:NSCaseInsensitiveSearch] )
			{
			#if defined(__USE_ID_AS_KEY__) && __USE_ID_AS_KEY__
				[self mapPropertyAsKey:propertyName atPath:nil defaultValue:defaultValue];
			#else	// #if defined(__USE_ID_AS_KEY__) && __USE_ID_AS_KEY__
				[self mapProperty:propertyName atPath:nil defaultValue:defaultValue];
			#endif	// #if defined(__USE_ID_AS_KEY__) && __USE_ID_AS_KEY__
			}
			else
			{
				[self mapProperty:propertyName atPath:nil defaultValue:defaultValue];
			}
		}
		
		clazzType = class_getSuperclass( clazzType );
		if ( nil == clazzType || clazzType == [BeeActiveRecord class] )
			break;
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ( _deleted )
		return;
	
	NSDictionary * property = (NSDictionary *)context;
	if ( nil == property )
		return;

	static BOOL __enterred = NO;
	if ( NO == __enterred )
	{
		__enterred = YES;

		NSObject * obj1 = [change objectForKey:@"new"];
		NSObject * obj2 = [change objectForKey:@"old"];
		
		if ( NO == [obj1 isEqual:obj2] )
		{
			_changed = YES;
		}

		NSString * name = [property objectForKey:@"name"];
		NSString * path = [property objectForKey:@"path"];
		NSNumber * type = [property objectForKey:@"type"];

		NSObject * value = [change objectForKey:@"new"]; // [self valueForKey:name];

		if ( object == self )
		{
			// sync property to JSON

	//		NSObject * value = [self valueForKey:name];
			if ( value )
			{
				if ( BeeTypeEncoding.NSNUMBER == type.intValue )
				{
					value = [value asNSNumber];
				}
				else if ( BeeTypeEncoding.NSSTRING == type.intValue )
				{
					value = [value asNSString];
				}
				else if ( BeeTypeEncoding.NSDATE == type.intValue )
				{
					value = [value asNSString];
				}
			}

			if ( path && value )
			{
				[_JSON setObject:value atPath:path];
			}
		}
		else if ( object == _JSON )
		{
			// sync JSON to property
			
	//		NSObject * value = [_JSON objectAtPath:path];
			if ( value )
			{
				if ( BeeTypeEncoding.NSNUMBER == type.intValue )
				{
					value = [value asNSNumber];
				}
				else if ( BeeTypeEncoding.NSSTRING == type.intValue )
				{
					value = [value asNSString];
				}
				else if ( BeeTypeEncoding.NSDATE == type.intValue )
				{
					value = [value asNSDate];
				}
			}
			
			if ( name && value )
			{
				[self setValue:value forKey:name];
			}
		}
				
		__enterred = NO;
	}
}

- (void)initSelf
{
	[[self class] prepareOnceWithRootClass:[BeeActiveRecord class]];
	
	if ( [[self class] usingJSON] )
	{
		_JSON = [[NSMutableDictionary alloc] init];	
	}
	
	_changed = YES;
	_deleted = NO;
	
	NSMutableDictionary * propertySet = self.activePropertySet;
	if ( propertySet && propertySet.count )
	{		
		for ( NSString * key in propertySet.allKeys )
		{
			NSDictionary * property = [propertySet objectForKey:key];
			
			NSString * name = [property objectForKey:@"name"];
			NSString * path = [property objectForKey:@"path"];
			NSNumber * type = [property objectForKey:@"type"];

			NSObject * value = [property objectForKey:@"value"];
			
			if ( value && NO == [value isKindOfClass:[NonValue class]] )
			{
				if ( value )
				{
					if ( BeeTypeEncoding.NSNUMBER == type.intValue )
					{
						value = [value asNSNumber];
					}
					else if ( BeeTypeEncoding.NSSTRING == type.intValue )
					{
						value = [value asNSString];
					}
					else if ( BeeTypeEncoding.NSDATE == type.intValue )
					{
						value = [value asNSString];
					}
				}
			
				[self setValue:value forKey:name];

				[_JSON setObject:value atPath:path];
			}
		}
	}
}

- (void)setObservers
{
	NSMutableDictionary * propertySet = self.activePropertySet;
	if ( propertySet && propertySet.count )
	{
		for ( NSString * key in propertySet.allKeys )
		{
			NSDictionary * property = [propertySet objectForKey:key];

			NSString * name = [property objectForKey:@"name"];
			NSString * path = [property objectForKey:@"path"];

			[self addObserver:self
				   forKeyPath:name
					  options:NSKeyValueObservingOptionNew//|NSKeyValueObservingOptionOld
					  context:property];

			[_JSON addObserver:self
					forKeyPath:path
					   options:NSKeyValueObservingOptionNew//|NSKeyValueObservingOptionOld
					   context:property];
		}
	}	
}

- (void)removeObservers
{
	NSMutableDictionary * propertySet = self.activePropertySet;
	if ( propertySet && propertySet.count )
	{
		for ( NSString * key in propertySet.allKeys )
		{
			NSDictionary * property = [propertySet objectForKey:key];
			
			NSString * name = [property objectForKey:@"name"];
			NSString * path = [property objectForKey:@"path"];
			
			[self removeObserver:self forKeyPath:name];
			[_JSON removeObserver:self forKeyPath:path];
		}
	}
}

- (id)init
{
	self = [super init];
	if ( self )
	{
		[self initSelf];
		
		[self setObservers];
		[self load];
	}
	return self;
}

- (id)initWithObject:(NSObject *)object
{
	self = [super init];
	if ( self )
	{
		[self initSelf];

		if ( [object isKindOfClass:[self class]] )
		{
			[self setDictionary:((BeeActiveRecord *)object).JSON];
		}
		else if ( [object isKindOfClass:[NSString class]] )
		{
			NSObject * dict = [(NSString *)object objectFromJSONString];
			if ( dict && [dict isKindOfClass:[NSDictionary class]] )
			{
				[self setDictionary:(NSDictionary *)dict];
			}
		}
		else if ( [object isKindOfClass:[NSData class]] )
		{
			NSObject * dict = [(NSData *)object objectFromJSONData];
			if ( dict && [dict isKindOfClass:[NSDictionary class]] )
			{
				[self setDictionary:(NSDictionary *)dict];
			}
		}
		else if ( [object isKindOfClass:[NSDictionary class]] )
		{
			[self setDictionary:(NSDictionary *)object];
		}
		else if ( [object isKindOfClass:[BeeActiveRecord class]] )
		{
			[self setDictionary:((BeeActiveRecord *)object).JSON];
		}
		else
		{
			CC( @"Unknown object type" );
		}

		[self setObservers];
		[self load];
	}
	return self;
}

- (id)initWithDictionary:(NSDictionary *)otherDictionary
{
	self = [super init];
	if ( self )
	{
		[self initSelf];
		[self setDictionary:otherDictionary];
		
		[self setObservers];
		[self load];
	}
	return self;
}

- (id)initWithJSONData:(NSData *)data
{
	self = [super init];
	if ( self )
	{
		[self initSelf];
		
		NSObject * object = [data objectFromJSONDataWithParseOptions:JKParseOptionComments|JKParseOptionLooseUnicode];
		if ( object && [object isKindOfClass:[NSDictionary class]] )
		{
			[self setDictionary:(NSDictionary *)object];
		}

		[self setObservers];
		[self load];
	}
	return self;
}

- (id)initWithJSONString:(NSString *)string
{
	self = [super init];
	if ( self )
	{
		[self initSelf];

		NSObject * object = [string objectFromJSONStringWithParseOptions:JKParseOptionComments|JKParseOptionLooseUnicode];
		if ( object && [object isKindOfClass:[NSDictionary class]] )
		{
			[self setDictionary:(NSDictionary *)object];
		}
		
		[self setObservers];
		[self load];
	}
	return self;	
}

+ (id)record
{
	return [[[[self class] alloc] init] autorelease];
}

+ (id)record:(NSObject *)otherObject
{
	return [[[[self class] alloc] initWithObject:otherObject] autorelease];
}

+ (id)recordWithObject:(NSObject *)otherObject
{
	return [[[[self class] alloc] initWithObject:otherObject] autorelease];
}

+ (id)recordWithDictionary:(NSDictionary *)dict
{
	return [[[[self class] alloc] initWithDictionary:dict] autorelease];
}

+ (id)recordWithJSONData:(NSData *)data
{
	return [[[[self class] alloc] initWithJSONData:data] autorelease];
}

+ (id)recordWithJSONString:(NSString *)string
{
	return [[[[self class] alloc] initWithJSONString:string] autorelease];
}

- (void)load
{
	
}

- (void)unload
{
	
}

- (void)dealloc
{
	[self update];
	[self unload];
	[self removeObservers];
	
	[_JSON release];
	
	[super dealloc];
}

- (id)valueForUndefinedKey:(NSString *)key
{
	return nil;
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
	CC( @"[ERROR] undefined key '%@'", key );
}

- (NSString *)description
{
	NSMutableString *		desc = [NSMutableString string];
	NSMutableDictionary *	propertySet = self.activePropertySet;
	
	[desc appendFormat:@"%s(%p) = { ", class_getName( [self class] ), self];

	for ( NSString * key in propertySet.allKeys )
	{
		NSDictionary * property = [propertySet objectForKey:key];
		
		NSString * name = [property objectForKey:@"name"];
		NSNumber * type = [property objectForKey:@"type"];
		
		NSObject * value = [self valueForKey:name];
		if ( value && NO == [value isKindOfClass:[NSNull class]] )
		{
			[desc appendFormat:@", "];

			if ( BeeTypeEncoding.NSNUMBER == type.intValue )
			{
				value = [value asNSNumber];
				
				[desc appendFormat:@"'%@' : %@", name, value];
			}
			else if ( BeeTypeEncoding.NSSTRING == type.intValue )
			{
				value = [value asNSString];
				
				[desc appendFormat:@"'%@' : '%@'", name, value];
			}
			else if ( BeeTypeEncoding.NSDATE == type.intValue )
			{
				value = [value asNSDate];
				
				[desc appendFormat:@"'%@' : '%@'", name, value];
			}
			else
			{
//				value = [value asNSNumber];

				[desc appendFormat:@"'%@' : <%@>", name, value];
			}
		}
	}
	
	[desc appendFormat:@" }"];

	return desc;
}

+ (void)setAssociateConditions
{
	NSMutableDictionary * propertySet = [[self class] activePropertySet];
	
	for ( NSString * key in propertySet.allKeys )
	{
		NSDictionary * property = [propertySet objectForKey:key];
		
		NSString * name = [property objectForKey:@"name"];
		NSNumber * type = [property objectForKey:@"type"];
		NSObject * value = nil;
		
		NSString * associateClass = [property objectForKey:@"associateClass"];
		NSString * associateProperty = [property objectForKey:@"associateProperty"];
		
		if ( associateClass )
		{
			Class classType = NSClassFromString( associateClass );
			if ( classType )
			{
				NSObject * obj = [super.DB associateObjectFor:classType];
				if ( obj )
				{
					if ( associateProperty )
					{
						value = [obj valueForKey:associateProperty];
					}
					else
					{
						value = [obj valueForKey:classType.activePrimaryKey];
					}
				}
			}
		}
		
		if ( value && NO == [value isKindOfClass:[NSNull class]] )
		{
			if ( BeeTypeEncoding.NSNUMBER == type.intValue )
			{
				value = [value asNSNumber];
			}
			else if ( BeeTypeEncoding.NSSTRING == type.intValue )
			{
				value = [value asNSString];
			}
			else if ( BeeTypeEncoding.NSDATE == type.intValue )
			{
				value = [value asNSDate];
			}
			else
			{
//				value = [value asNSNumber];
			}
			
			super.DB.WHERE( name, value );
		}
		
	}
}

- (void)setPropertiesFrom:(NSDictionary *)dict
{
	if ( nil == dict )
		return;
	
	NSMutableDictionary * propertySet = self.activePropertySet;
	
	for ( NSString * key in propertySet.allKeys )
	{
		NSDictionary * property = [propertySet objectForKey:key];
		
		NSString * name = [property objectForKey:@"name"];
		NSString * path = [property objectForKey:@"path"];
		NSNumber * type = [property objectForKey:@"type"];
		NSObject * value = nil;
		
		NSString * associateClass = [property objectForKey:@"associateClass"];
		NSString * associateProperty = [property objectForKey:@"associateProperty"];
		
		if ( associateClass )
		{
			Class classType = NSClassFromString( associateClass );
			if ( classType )
			{
				NSObject * obj = [super.DB associateObjectFor:classType];
				if ( obj )
				{
					if ( associateProperty )
					{
						value = [obj valueForKey:associateProperty];
					}
					else
					{
						value = [obj valueForKey:classType.activePrimaryKey];	
					}
				}
			}			
		}
		
		if ( nil == value )
		{
			value = [dict objectAtPath:path];
		}
		
		if ( value && NO == [value isKindOfClass:[NSNull class]] )
		{
			if ( BeeTypeEncoding.NSNUMBER == type.intValue )
			{
				value = [value asNSNumber];
			}
			else if ( BeeTypeEncoding.NSSTRING == type.intValue )
			{
				value = [value asNSString];
			}
			else if ( BeeTypeEncoding.NSDATE == type.intValue )
			{
				value = [value asNSDate];
			}
			else
			{
//				value = [value asNSNumber];
			}
			
			[self setValue:value forKey:name];
		}
	}
}

- (void)setDictionary:(NSDictionary *)dict
{
	[self setPropertiesFrom:dict];
	
	[_JSON setDictionary:dict];
}

- (NSDictionary *)JSON
{
	return _JSON;
}

- (void)setJSON:(NSMutableDictionary *)JSON
{
	[self setDictionary:JSON];
}

- (NSData *)JSONData
{
	return [_JSON JSONData];
}

- (void)setJSONData:(NSData *)data
{
	NSObject * object = [data objectFromJSONDataWithParseOptions:JKParseOptionComments|JKParseOptionLooseUnicode];
	if ( object && [object isKindOfClass:[NSDictionary class]] )
	{
		[self setDictionary:(NSDictionary *)object];
	}
}

- (NSString *)JSONString
{
	return [_JSON JSONString];
}

- (void)setJSONString:(NSString *)string
{
	NSObject * object = [string objectFromJSONStringWithParseOptions:JKParseOptionComments|JKParseOptionLooseUnicode];
	if ( object && [object isKindOfClass:[NSDictionary class]] )
	{
		[self setDictionary:(NSDictionary *)object];
	}
}

- (BOOL)get
{
	NSString * primaryKey = self.activePrimaryKey;
	
	super.DB
	.FROM( self.tableName )
	.WHERE( primaryKey, [self valueForKey:primaryKey] )
	.LIMIT( 1 )
	.GET();
	
	if ( super.DB.succeed )
	{
		NSDictionary * dict = [super.DB.resultArray objectAtIndex:0];
		if ( dict )
		{
			[self setPropertiesFrom:dict];
			
			NSString * json = [dict objectForKey:self.activeJSONKey];
			if ( json && json.length )
			{
				NSObject * object = [json objectFromJSONString];
				if ( object && [object isKindOfClass:[NSDictionary class]] )
				{
					[_JSON removeAllObjects];
					[_JSON setDictionary:(NSDictionary *)object];
				}
			}
			
			return YES;
		}
	}
	
	return NO;
}

- (BOOL)exists
{
	NSString * primaryKey = self.activePrimaryKey;

	super.DB
	.FROM( self.tableName )
	.WHERE( primaryKey, [self valueForKey:primaryKey] )
	.LIMIT( 1 )
	.COUNT();

	if ( super.DB.succeed && super.DB.resultCount > 0 )
	{
		return YES;
	}

	return NO;
}

- (BOOL)insert
{
	if ( _deleted )
		return NO;

	super.DB.FROM( self.tableName );

	NSString *		JSONKey = self.activeJSONKey;
	NSDictionary *	propertySet = self.activePropertySet;

	for ( NSString * key in propertySet.allKeys )
	{
		NSDictionary * property = [propertySet objectForKey:key];
		
		NSString * name = [property objectForKey:@"name"];
		NSNumber * type = [property objectForKey:@"type"];

		if ( [name isEqualToString:JSONKey] )
			continue;

		NSObject * value = [self valueForKey:name];
		if ( value )
		{
			if ( BeeTypeEncoding.NSNUMBER == type.intValue )
			{
				value = [value asNSNumber];
			}
			else if ( BeeTypeEncoding.NSSTRING == type.intValue )
			{
				value = [value asNSString];
			}
			else if ( BeeTypeEncoding.NSDATE == type.intValue )
			{
				value = [value asNSDate];
			}
			else
			{
//				value = [value asNSNumber];
			}

			super.DB.SET( name, value );
		}
	}
	
	if ( [[self class] usingJSON] )
	{
		super.DB.SET( self.activeJSONKey, self.JSONString );
	}
	
	super.DB.INSERT();

	if ( super.DB.succeed )
	{
		_changed = NO;
		return YES;
	}
	
	return NO;
}

- (BOOL)update
{
	if ( _deleted || NO == _changed )
		return NO;

	NSString *		JSONKey = self.activeJSONKey;
	NSString *		primaryKey = self.activePrimaryKey;
	NSObject *		primaryID = [self valueForKey:primaryKey];
	NSDictionary *	propertySet = self.activePropertySet;
	
	super.DB
	.FROM( self.tableName )
	.WHERE( primaryKey, primaryID );
	
	for ( NSString * key in propertySet.allKeys )
	{
		NSDictionary * property = [propertySet objectForKey:key];
		
		NSString * name = [property objectForKey:@"name"];
		NSNumber * type = [property objectForKey:@"type"];

		if ( [name isEqualToString:JSONKey] )
			continue;
		
		NSObject * value = [self valueForKey:name];
		if ( value )
		{
			if ( BeeTypeEncoding.NSNUMBER == type.intValue )
			{
				value = [value asNSNumber];
			}
			else if ( BeeTypeEncoding.NSSTRING == type.intValue )
			{
				value = [value asNSString];
			}
			else if ( BeeTypeEncoding.NSDATE == type.intValue )
			{
				value = [value asNSDate];
			}
			else
			{
//				value = [value asNSNumber];
			}
			
			super.DB.SET( name, value );
		}
	}

	if ( [[self class] usingJSON] )
	{
		super.DB.SET( self.activeJSONKey, self.JSONString );
	}
	
	super.DB.UPDATE();
	
	return super.DB.succeed;
}

- (BOOL)delete
{
	if ( _deleted )
		return NO;
	
	NSString *		JSONKey = self.activeJSONKey;
	NSString *		primaryKey = self.activePrimaryKey;
	NSObject *		primaryID = [self valueForKey:primaryKey];
	NSDictionary *	propertySet = self.activePropertySet;

	super.DB
	.FROM( self.tableName )
	.WHERE( primaryKey, primaryID )
	.DELETE();

	if ( super.DB.succeed )
	{
		for ( NSString * key in propertySet.allKeys )
		{
			NSDictionary * property = [propertySet objectForKey:key];
			
			NSString * name = [property objectForKey:@"name"];
			if ( [name isEqualToString:JSONKey] )
				continue;

			NSObject * value = [property objectForKey:@"value"];
			if ( value && NO == [value isKindOfClass:[NonValue class]] )
			{
				[self setValue:value forKey:name];
			}
			else
			{
				[self setValue:nil forKey:name];
			}
		}

		[_JSON removeAllObjects];

		_changed = NO;
		_deleted = YES;

		return YES;
	}
		
	return NO;
}

- (BeeDatabaseBoolBlock)EXISTS
{
	BeeDatabaseBoolBlock block = ^ BOOL ( void )
	{
		return [self exists];
	};
	
	return [[block copy] autorelease];
}

- (BeeDatabaseBoolBlock)INSERT
{
	BeeDatabaseBoolBlock block = ^ BOOL ( void )
	{
		return [self insert];
	};
	
	return [[block copy] autorelease];
}

- (BeeDatabaseBoolBlock)UPDATE
{
	BeeDatabaseBoolBlock block = ^ BOOL ( void )
	{
		return [self update];
	};
	
	return [[block copy] autorelease];
}

- (BeeDatabaseBoolBlock)DELETE
{
	BeeDatabaseBoolBlock block = ^ BOOL ( void )
	{
		return [self delete];
	};
	
	return [[block copy] autorelease];
}

- (BeeDatabaseBoolBlock)LOAD
{
	BeeDatabaseBoolBlock block = ^ BOOL ( void )
	{
		return [self get];
		
		return YES;
	};
	
	return [[block copy] autorelease];
}

- (BeeDatabaseBoolBlock)SAVE
{
	BeeDatabaseBoolBlock block = ^ BOOL ( void )
	{
		BOOL ret = [self exists];
		if ( NO == ret )
		{
			ret = [self insert];
		}
		else
		{
			ret = [self update];
		}
		return ret;
	};

	return [[block copy] autorelease];
}

@end

#pragma mark -

@implementation NSArray(BeeActiveRecord)

- (NSArray *)activeRecordsFromArray:(Class)clazz
{
	NSMutableArray * array = [NSMutableArray array];
	
	for ( NSObject * obj in self )
	{
		if ( [obj isKindOfClass:[NSDictionary class]] )
		{
			BeeActiveRecord * record = [(NSDictionary *)obj activeRecordFromDictionary:clazz];
			if ( record )
			{
				[array addObject:record];
			}
		}
	}

	return array;
}

@end

#pragma mark -

@implementation NSDictionary(BeeActiveRecord)

- (BeeActiveRecord *)activeRecordFromDictionary:(Class)clazz
{
	if ( NO == [clazz isSubclassOfClass:[BeeActiveRecord class]] )
		return nil;

	return [[[clazz alloc] initWithDictionary:self] autorelease];
}

@end

#pragma mark -

@implementation BeeDatabase(BeeActiveRecord)

@dynamic BELONG_TO;

@dynamic SAVE;
@dynamic SAVE_ARRAY;
@dynamic SAVE_DICTIONARY;

@dynamic GET_RECORDS;
@dynamic FIRST_RECORD;
@dynamic FIRST_RECORD_BY_ID;
@dynamic LAST_RECORD;
@dynamic LAST_RECORD_BY_ID;

- (BeeDatabaseBlockN)BELONG_TO
{
	BeeDatabaseBlockN block = ^ BeeDatabase * ( id first, ... )
	{
		return self.ASSOCIATE( first );
	};
	
	return [[block copy] autorelease];
}

- (BeeDatabaseBlockN)SAVE
{
	BeeDatabaseBlockN block = ^ BeeDatabase * ( id first, ... )
	{
		if ( [first isKindOfClass:[NSArray class]] )
		{
			return [self saveArray:(NSArray *)first];
		}
		else if ( [first isKindOfClass:[NSDictionary class]] )
		{
			return [self saveDictionary:(NSDictionary *)first];
		}
		
		return self;
	};
	
	return [[block copy] autorelease];
}

- (BeeDatabaseBlockN)SAVE_ARRAY
{
	BeeDatabaseBlockN block = ^ BeeDatabase * ( id first, ... )
	{
		return [self saveArray:(NSArray *)first];
	};
	
	return [[block copy] autorelease];
}

- (BeeDatabaseBlockN)SAVE_DICTIONARY
{
	BeeDatabaseBlockN block = ^ BeeDatabase * ( id first, ... )
	{
		return [self saveDictionary:(NSDictionary *)first];
	};
	
	return [[block copy] autorelease];
}

- (BeeDatabaseArrayBlock)GET_RECORDS
{
	BeeDatabaseArrayBlock block = ^ NSArray * ( void )
	{
		return [self getRecords];
	};
	
	return [[block copy] autorelease];
}

- (BeeDatabaseObjectBlock)FIRST_RECORD
{
	BeeDatabaseObjectBlock block = ^ NSArray * ( void )
	{
		return [self firstRecord];
	};
	
	return [[block copy] autorelease];
}

- (BeeDatabaseObjectBlockN)FIRST_RECORD_BY_ID
{
	BeeDatabaseObjectBlockN block = ^ NSArray * ( id first, ... )
	{
		return [self firstRecord:nil byID:first];
	};
	
	return [[block copy] autorelease];
}

- (BeeDatabaseObjectBlock)LAST_RECORD
{
	BeeDatabaseObjectBlock block = ^ NSArray * ( void )
	{
		return [self lastRecord];
	};
	
	return [[block copy] autorelease];
}

- (BeeDatabaseObjectBlockN)LAST_RECORD_BY_ID
{
	BeeDatabaseObjectBlockN block = ^ NSArray * ( id first, ... )
	{
		return [self lastRecord:nil byID:first];
	};
	
	return [[block copy] autorelease];
}

- (id)saveArray:(NSArray *)array
{
	Class classType = self.classType;
	
	for ( NSObject * obj in array )
	{
		if ( NO == [obj isKindOfClass:[NSDictionary class]] )
			continue;
		
		[self CLASS_TYPE]( classType );
		[self saveDictionary:(NSDictionary *)obj];
	}
	
	return self;
}

- (id)saveDictionary:(NSDictionary *)dict
{
	Class classType = self.classType;
	if ( NO == [classType isSubclassOfClass:[BeeActiveRecord class]] )
		return self;
	
	BeeActiveRecord * record = [dict activeRecordFromDictionary:classType];
	if ( record )
	{
		record.SAVE();
	}

	return self;
}

- (id)firstRecord
{
	return [self firstRecord:nil];
}

- (id)firstRecord:(NSString *)table
{
	NSArray * array = [self getRecords:table limit:1 offset:0];
	if ( array && array.count )
	{
		return [array objectAtIndex:0];
	}

	return nil;
}

- (id)firstRecordByID:(id)key
{
	return [self firstRecord:nil byID:key];
}

- (id)firstRecord:(NSString *)table byID:(id)key
{
	[self __internalResetResult];

	Class classType = [self classType];
	if ( NULL == classType )
		return nil;

	NSString * primaryKey = [BeeActiveRecord activePrimaryKeyFor:classType];
	if ( nil == primaryKey )
		return nil;
	
	[classType setAssociateConditions];
	
	self.WHERE( primaryKey, key ).OFFSET( 0 ).LIMIT( 1 ).GET();
	if ( NO == self.succeed )
		return nil;

	NSArray * array = self.resultArray;
	if ( nil == array || 0 == array.count )
		return nil;
	
	NSDictionary * dict = [array objectAtIndex:0];
	if ( dict )
	{
		return [[[classType alloc] initWithDictionary:dict] autorelease];
	}
	
	return nil;
}

- (id)lastRecord
{
	return [self lastRecord:nil];
}

- (id)lastRecord:(NSString *)table
{
	NSArray * array = [self getRecords:table limit:1 offset:0];
	if ( array && array.count )
	{
		return array.lastObject;
	}
	
	return nil;
}

- (id)lastRecordByID:(id)key
{
	return [self lastRecord:nil byID:key];
}

- (id)lastRecord:(NSString *)table byID:(id)key
{
	[self __internalResetResult];
	
	Class classType = [self classType];
	if ( NULL == classType )
		return nil;
	
	NSString * primaryKey = [BeeActiveRecord activePrimaryKeyFor:classType];
	if ( nil == primaryKey )
		return nil;
	
	[classType setAssociateConditions];
	
	self.WHERE( primaryKey, key ).OFFSET( 0 ).LIMIT( 1 ).GET();
	if ( NO == self.succeed )
		return nil;
	
	NSArray * array = self.resultArray;
	if ( nil == array || 0 == array.count )
		return nil;
	
	NSDictionary * dict = array.lastObject;
	if ( dict )
	{
		return [[[classType alloc] initWithDictionary:dict] autorelease];
	}
	
	return nil;
}

- (NSArray *)getRecords
{
	return [self getRecords:nil limit:0 offset:0];
}

- (NSArray *)getRecords:(NSString *)table
{
	return [self getRecords:table limit:0 offset:0];
}

- (NSArray *)getRecords:(NSString *)table limit:(NSUInteger)limit
{
	return [self getRecords:table limit:limit offset:0];
}

- (NSArray *)getRecords:(NSString *)table limit:(NSUInteger)limit offset:(NSUInteger)offset
{
	[self __internalResetResult];
	
	Class classType = [self classType];
	if ( NULL == classType )
		return [NSArray array];
	
	NSString * primaryKey = [BeeActiveRecord activePrimaryKeyFor:classType];
	if ( nil == primaryKey )
		return [NSArray array];
	
	[classType setAssociateConditions];
	
	self.OFFSET( offset ).LIMIT( limit ).GET();
	if ( NO == self.succeed )
		return [NSArray array];
	
	NSArray * array = self.resultArray;
	if ( nil == array || 0 == array.count )
		return [NSArray array];

	NSMutableArray * activeRecords = [[NSMutableArray alloc] init];
	
	for ( NSDictionary * dict in array )
	{
		BeeActiveRecord * object = [[[classType alloc] initWithDictionary:dict] autorelease];
		[activeRecords addObject:object];
	}

	[_resultArray removeAllObjects];
	[_resultArray addObjectsFromArray:activeRecords];
	
	[activeRecords release];
	
	return _resultArray;
}

@end
