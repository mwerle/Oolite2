/*

OOJSMission.m


Oolite
Copyright (C) 2004-2008 Giles C Williams and contributors

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
MA 02110-1301, USA.

*/

#import "OOJSMission.h"
#import "OOJavaScriptEngine.h"
#import "OOJSScript.h"

#import "OOJSPlayer.h"


static JSBool MissionGetProperty(JSContext *context, JSObject *this, jsval name, jsval *outValue);

static JSBool MissionShowMissionScreen(JSContext *context, JSObject *this, uintN argc, jsval *argv, jsval *outResult);
static JSBool MissionShowShipModel(JSContext *context, JSObject *this, uintN argc, jsval *argv, jsval *outResult);
static JSBool MissionResetMissionChoice(JSContext *context, JSObject *this, uintN argc, jsval *argv, jsval *outResult);
static JSBool MissionMarkSystem(JSContext *context, JSObject *this, uintN argc, jsval *argv, jsval *outResult);
static JSBool MissionUnmarkSystem(JSContext *context, JSObject *this, uintN argc, jsval *argv, jsval *outResult);
static JSBool MissionAddMessageTextKey(JSContext *context, JSObject *this, uintN argc, jsval *argv, jsval *outResult);
static JSBool MissionAddMessageText(JSContext *context, JSObject *this, uintN argc, jsval *argv, jsval *outResult);
static JSBool MissionSetBackgroundImage(JSContext *context, JSObject *this, uintN argc, jsval *argv, jsval *outResult);
static JSBool MissionSetMusic(JSContext *context, JSObject *this, uintN argc, jsval *argv, jsval *outResult);
static JSBool MissionSetChoicesKey(JSContext *context, JSObject *this, uintN argc, jsval *argv, jsval *outResult);
static JSBool MissionSetInstructionsKey(JSContext *context, JSObject *this, uintN argc, jsval *argv, jsval *outResult);
static JSBool MissionClearMissionScreen(JSContext *context, JSObject *this, uintN argc, jsval *argv, jsval *outResult);

static JSClass sMissionClass =
{
	"Mission",
	0,
	
	JS_PropertyStub,
	JS_PropertyStub,
	MissionGetProperty,
	JS_PropertyStub,
	JS_EnumerateStub,
	JS_ResolveStub,
	JS_ConvertStub,
	JS_FinalizeStub
};


enum
{
	// Property IDs
	kMission_choice,			// selected option, string, read-only.
};


static JSPropertySpec sMissionProperties[] =
{
	// JS name					ID							flags
	{ "choice",					kMission_choice,			JSPROP_PERMANENT | JSPROP_READONLY | JSPROP_ENUMERATE },
	{ 0 }	
};


static JSFunctionSpec sMissionMethods[] =
{
	// JS name					Function					min args
	{ "showMissionScreen",		MissionShowMissionScreen,	0 },
	{ "showShipModel",			MissionShowShipModel,		1 },
	{ "resetMissionChoice",		MissionResetMissionChoice,	0 },
	{ "markSystem",				MissionMarkSystem,			1 },
	{ "unmarkSystem",			MissionUnmarkSystem,		1 },
	{ "addMessageTextKey",		MissionAddMessageTextKey,	1 },
	{ "addMessageText",			MissionAddMessageText,		1 },
	{ "setBackgroundImage",		MissionSetBackgroundImage,	1 },
	{ "setMusic",				MissionSetMusic,			1 },
	{ "setChoicesKey",			MissionSetChoicesKey,		1 },
	{ "setInstructionsKey",		MissionSetInstructionsKey,	1 },
	{ "clearMissionScreen",		MissionClearMissionScreen,	0 },
	{ 0 }
};


void InitOOJSMission(JSContext *context, JSObject *global)
{
	JSObject *missionPrototype = JS_InitClass(context, global, NULL, &sMissionClass, NULL, 0, sMissionProperties, sMissionMethods, NULL, NULL);
	JS_DefineObject(context, global, "mission", &sMissionClass, missionPrototype, JSPROP_ENUMERATE | JSPROP_READONLY | JSPROP_PERMANENT);
}


static JSBool MissionGetProperty(JSContext *context, JSObject *this, jsval name, jsval *outValue)
{
	id							result = nil;
	PlayerEntity				*player = nil;
	
	if (!JSVAL_IS_INT(name))  return YES;
	
	player = OOPlayerForScripting();
	
	switch (JSVAL_TO_INT(name))
	{
		case kMission_choice:
			result = [player missionChoice_string];
			if (result == nil)  result = [NSNull null];
			break;
	}
	
	if (result != nil) *outValue = [result javaScriptValueInContext:context];
	return YES;
}


static JSBool MissionShowMissionScreen(JSContext *context, JSObject *obj, uintN argc, jsval *argv, jsval *rval)
{
	PlayerEntity		*player = OOPlayerForScripting();
	
	[player setGuiToMissionScreen];
	
	return YES;
}


static JSBool MissionShowShipModel(JSContext *context, JSObject *obj, uintN argc, jsval *argv, jsval *rval)
{
	PlayerEntity		*player = OOPlayerForScripting();
	
	// If argv[0] can't be converted to a string -- e.g., null or undefined -- this will clear the ship model.
	[player showShipModel:[NSString stringWithJavaScriptValue:argv[0] inContext:context]];
	
	return YES;
}


static JSBool MissionResetMissionChoice(JSContext *context, JSObject *obj, uintN argc, jsval *argv, jsval *rval)
{
	PlayerEntity		*player = OOPlayerForScripting();
	
	[player resetMissionChoice];
	
	return YES;
}


static JSBool MissionMarkSystem(JSContext *context, JSObject *obj, uintN argc, jsval *argv, jsval *rval)
{
	PlayerEntity		*player = OOPlayerForScripting();
	NSString			*params = nil;
	
	params = [NSString concatenationOfStringsFromJavaScriptValues:argv count:argc separator:@" " inContext:context];
	[player addMissionDestination:params];
	
	return YES;
}


static JSBool MissionUnmarkSystem(JSContext *context, JSObject *obj, uintN argc, jsval *argv, jsval *rval)
{
	PlayerEntity		*player = OOPlayerForScripting();
	NSString			*params = nil;
	
	params = [NSString concatenationOfStringsFromJavaScriptValues:argv count:argc separator:@" " inContext:context];
	[player removeMissionDestination:params];
	
	return YES;
}


static JSBool MissionAddMessageTextKey(JSContext *context, JSObject *this, uintN argc, jsval *argv, jsval *outResult)
{
	PlayerEntity		*player = OOPlayerForScripting();
	NSString			*key = nil;
	
	key = [NSString stringWithJavaScriptValue:argv[0] inContext:context];
	[player addMissionText:key];
	
	return YES;
}


static JSBool MissionAddMessageText(JSContext *context, JSObject *this, uintN argc, jsval *argv, jsval *outResult)
{
	PlayerEntity		*player = OOPlayerForScripting();
	NSString			*text = nil;
	
	text = [NSString stringWithJavaScriptValue:argv[0] inContext:context];
	[player addLiteralMissionText:text];
	
	return YES;
}


static JSBool MissionSetBackgroundImage(JSContext *context, JSObject *this, uintN argc, jsval *argv, jsval *outResult)
{
	PlayerEntity		*player = OOPlayerForScripting();
	NSString			*key = nil;
	
	if (argc >= 1)  key = [NSString stringWithJavaScriptValue:argv[0] inContext:context];
	[player setMissionImage:key];
	
	return YES;
}


static JSBool MissionSetMusic(JSContext *context, JSObject *this, uintN argc, jsval *argv, jsval *outResult)
{
	PlayerEntity		*player = OOPlayerForScripting();
	NSString			*key = nil;
	
	key = [NSString stringWithJavaScriptValue:argv[0] inContext:context];
	[player setMissionMusic:key];
	
	return YES;
}


static JSBool MissionSetChoicesKey(JSContext *context, JSObject *this, uintN argc, jsval *argv, jsval *outResult)
{
	PlayerEntity		*player = OOPlayerForScripting();
	NSString			*key = nil;
	
	key = [NSString stringWithJavaScriptValue:argv[0] inContext:context];
	[player setMissionChoices:key];
	
	return YES;
}


// setInstructionsKey(instructionsKey : String [, missionKey : String])
static JSBool MissionSetInstructionsKey(JSContext *context, JSObject *this, uintN argc, jsval *argv, jsval *outResult)
{
	PlayerEntity		*player = OOPlayerForScripting();
	NSString			*key = nil;
	NSString			*missionKey = nil;
	
	key = [NSString stringWithJavaScriptValue:argv[0] inContext:context];
	
	if (argc > 1)
	{
		missionKey = [NSString stringWithJavaScriptValue:argv[1] inContext:context];
	}
	else
	{
		missionKey = [[OOJSScript currentlyRunningScript] name];
	}
	
	if (key != nil)
	{
		[player setMissionDescription:key forMission:missionKey];
	}
	else
	{
		[player clearMissionDescriptionForMission:missionKey];
	}
	
	return YES;
}


static JSBool MissionClearMissionScreen(JSContext *context, JSObject *this, uintN argc, jsval *argv, jsval *outResult)
{
	PlayerEntity		*player = OOPlayerForScripting();
	
	[player clearMissionScreen];
	return YES;
}
