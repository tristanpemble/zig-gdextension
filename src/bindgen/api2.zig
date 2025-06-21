const std = @import("std");
const gd = @import("godot");

pub const TODO = *anyopaque;

pub var library: gd.GDExtensionClassLibraryPtr = null;
pub var getProcAddress: gd.GDExtensionInterfaceGetProcAddress = null;

///
inline fn getProc(comptime T: type, comptime name: []const u8) std.meta.Child(T) {
    return struct {
        var proc: T = null;
        inline fn get() std.meta.Child(T) {
            if (proc) |p| {
                return p;
            } else {
                proc = @ptrCast(getProcAddress(name));
                return proc.?;
            }
        }
    }.get();
}

// Error types
pub const Error = error{
    InvalidCall,
    InvalidIndex,
    InvalidKey,
    InvalidType,
    InvalidMethod,
    InvalidProperty,
    NullPointer,
    OutOfMemory,
    NotFound,
};

// Generic function pointer types
pub const VariantFromTypeConstructorFunc = TODO; // GDExtensionVariantFromTypeConstructorFunc
pub const TypeFromVariantConstructorFunc = TODO; // GDExtensionTypeFromVariantConstructorFunc
pub const VariantGetInternalPtrFunc = TODO; // GDExtensionVariantGetInternalPtrFunc
pub const PtrOperatorEvaluator = TODO; // GDExtensionPtrOperatorEvaluator
pub const PtrBuiltInMethod = TODO; // GDExtensionPtrBuiltInMethod
pub const PtrConstructor = TODO; // GDExtensionPtrConstructor
pub const PtrDestructor = TODO; // GDExtensionPtrDestructor
pub const PtrSetter = TODO; // GDExtensionPtrSetter
pub const PtrGetter = TODO; // GDExtensionPtrGetter
pub const PtrIndexedSetter = TODO; // GDExtensionPtrIndexedSetter
pub const PtrIndexedGetter = TODO; // GDExtensionPtrIndexedGetter
pub const PtrKeyedSetter = TODO; // GDExtensionPtrKeyedSetter
pub const PtrKeyedGetter = TODO; // GDExtensionPtrKeyedGetter
pub const PtrKeyedChecker = TODO; // GDExtensionPtrKeyedChecker
pub const PtrUtilityFunction = TODO; // GDExtensionPtrUtilityFunction

// Editor function pointers
pub const EditorHelpLoadXmlFromUtf8Chars = TODO; // GDExtensionsInterfaceEditorHelpLoadXmlFromUtf8Chars
pub const EditorHelpLoadXmlFromUtf8CharsAndLen = TODO; // GDExtensionsInterfaceEditorHelpLoadXmlFromUtf8CharsAndLen

// Type aliases for C types
pub const GDExtensionVariantPtr = ?*anyopaque;
pub const GDExtensionConstVariantPtr = ?*const anyopaque;
pub const GDExtensionUninitializedVariantPtr = ?*anyopaque;
pub const GDExtensionStringNamePtr = ?*anyopaque;
pub const GDExtensionConstStringNamePtr = ?*const anyopaque;
pub const GDExtensionUninitializedStringNamePtr = ?*anyopaque;
pub const GDExtensionStringPtr = ?*anyopaque;
pub const GDExtensionConstStringPtr = ?*const anyopaque;
pub const GDExtensionUninitializedStringPtr = ?*anyopaque;
pub const GDExtensionObjectPtr = ?*anyopaque;
pub const GDExtensionConstObjectPtr = ?*const anyopaque;
pub const GDExtensionUninitializedObjectPtr = ?*anyopaque;
pub const GDExtensionTypePtr = ?*anyopaque;
pub const GDExtensionConstTypePtr = ?*const anyopaque;
pub const GDExtensionUninitializedTypePtr = ?*anyopaque;
pub const GDExtensionMethodBindPtr = ?*const anyopaque;
pub const GDExtensionRefPtr = ?*anyopaque;
pub const GDExtensionConstRefPtr = ?*const anyopaque;
pub const GDExtensionClassInstancePtr = ?*anyopaque;
pub const GDExtensionClassLibraryPtr = ?*anyopaque;
pub const GDExtensionScriptInstanceDataPtr = ?*anyopaque;
pub const GDExtensionScriptLanguagePtr = ?*anyopaque;
pub const GDExtensionScriptInstancePtr = ?*anyopaque;

// Core Types

pub const Variant = extern struct {
    data: [24]u8, // Adjust size based on actual variant size

    pub const Type = enum(u32) {
        nil = 0,
        bool = 1,
        int = 2,
        float = 3,
        string = 4,
        vector2 = 5,
        vector2i = 6,
        rect2 = 7,
        rect2i = 8,
        vector3 = 9,
        vector3i = 10,
        transform2d = 11,
        vector4 = 12,
        vector4i = 13,
        plane = 14,
        quaternion = 15,
        aabb = 16,
        basis = 17,
        transform3d = 18,
        projection = 19,
        color = 20,
        string_name = 21,
        node_path = 22,
        rid = 23,
        object = 24,
        callable = 25,
        signal = 26,
        dictionary = 27,
        array = 28,
        packed_byte_array = 29,
        packed_int32_array = 30,
        packed_int64_array = 31,
        packed_float32_array = 32,
        packed_float64_array = 33,
        packed_string_array = 34,
        packed_vector2_array = 35,
        packed_vector3_array = 36,
        packed_color_array = 37,
        packed_vector4_array = 38,
        max = 39,
    };

    pub const Operator = enum(u32) {
        equal = 0,
        not_equal = 1,
        less = 2,
        less_equal = 3,
        greater = 4,
        greater_equal = 5,
        add = 6,
        subtract = 7,
        multiply = 8,
        divide = 9,
        negate = 10,
        positive = 11,
        module = 12,
        power = 13,
        shift_left = 14,
        shift_right = 15,
        bit_and = 16,
        bit_or = 17,
        bit_xor = 18,
        bit_negate = 19,
        @"and" = 20,
        @"or" = 21,
        xor = 22,
        not = 23,
        in = 24,
        max = 25,
    };

    pub fn initNil() Variant { // GDExtensionInterfaceVariantNewNil
        const self: Variant = undefined;
        // TODO
        return self;
    }

    pub fn copy(other: *const Variant) void { // GDExtensionInterfaceVariantNewCopy
        const variantNewCopy = getProc(gd.GDExtensionInterfaceVariantNewCopy, "variant_new_copy");

        const self: Variant = undefined;
        _ = other;
        _ = variantNewCopy;
        return self;
    }

    pub fn deinit(self: *Variant) void { // GDExtensionInterfaceVariantDestroy
        _ = self;
    }

    pub fn getType(self: *const Variant) Type { // GDExtensionInterfaceVariantGetType
        _ = self;
        return .nil;
    }

    pub fn canConvert(from: Type, to: Type) bool { // GDExtensionInterfaceVariantCanConvert
        _ = from;
        _ = to;
        return false;
    }

    pub fn call(self: *Variant, method: *const StringName, args: []const *const Variant) Error!Variant { // GDExtensionInterfaceVariantCall
        _ = self;
        _ = method;
        _ = args;
        return error.NotFound;
    }

    pub fn callStatic(variant_type: Type, method: *const StringName, args: []const *const Variant) Error!Variant { // GDExtensionInterfaceVariantCallStatic
        _ = variant_type;
        _ = method;
        _ = args;
        return error.NotFound;
    }

    pub fn get(self: *const Variant, key: *const Variant) Error!Variant { // GDExtensionInterfaceVariantGet
        _ = self;
        _ = key;
        return error.NotFound;
    }

    pub fn set(self: *Variant, key: *const Variant, value: *const Variant) Error!void { // GDExtensionInterfaceVariantSet
        _ = self;
        _ = key;
        _ = value;
    }

    pub fn getIndexed(self: *const Variant, index: i64) Error!Variant { // GDExtensionInterfaceVariantGetIndexed
        _ = self;
        _ = index;
        return error.NotFound;
    }

    pub fn setIndexed(self: *Variant, index: i64, value: *const Variant) Error!void { // GDExtensionInterfaceVariantSetIndexed
        _ = self;
        _ = index;
        _ = value;
    }

    pub fn hash(self: *const Variant) i64 { // GDExtensionInterfaceVariantHash
        _ = self;
        return 0;
    }

    pub fn toBool(self: *const Variant) bool { // GDExtensionInterfaceVariantBooleanize
        _ = self;
        return false;
    }

    pub fn duplicate(self: *const Variant, deep: bool) Variant { // GDExtensionInterfaceVariantDuplicate
        _ = self;
        _ = deep;
        return Variant{ .data = undefined };
    }

    pub fn evaluate(op: Operator, left: *const Variant, right: *const Variant) Error!Variant { // GDExtensionInterfaceVariantEvaluate
        _ = op;
        _ = left;
        _ = right;
        return error.InvalidCall;
    }

    pub fn stringify(self: *const Variant) String { // GDExtensionInterfaceVariantStringify
        _ = self;
        return String{ .data = undefined };
    }

    pub fn canConvertStrict(from: Type, to: Type) bool { // GDExtensionInterfaceVariantCanConvertStrict
        _ = from;
        _ = to;
        return false;
    }

    pub fn construct(variant_type: Type, base: *Variant, args: []const *const Variant) void { // GDExtensionInterfaceVariantConstruct
        _ = variant_type;
        _ = base;
        _ = args;
    }

    pub fn getConstantValue(variant_type: Type, constant: *const StringName) Variant { // GDExtensionInterfaceVariantGetConstantValue
        _ = variant_type;
        _ = constant;
        return Variant{ .data = undefined };
    }

    pub fn getKeyed(self: *const Variant, key: *const Variant) Variant { // GDExtensionInterfaceVariantGetKeyed
        _ = self;
        _ = key;
        return Variant{ .data = undefined };
    }

    pub fn getNamed(self: *const Variant, name: *const StringName) Variant { // GDExtensionInterfaceVariantGetNamed
        _ = self;
        _ = name;
        return Variant{ .data = undefined };
    }

    pub fn setKeyed(self: *Variant, key: *const Variant, value: *const Variant) void { // GDExtensionInterfaceVariantSetKeyed
        _ = self;
        _ = key;
        _ = value;
    }

    pub fn setNamed(self: *Variant, name: *const StringName, value: *const Variant) void { // GDExtensionInterfaceVariantSetNamed
        _ = self;
        _ = name;
        _ = value;
    }

    pub fn getObjectInstanceId(self: *const Variant) u64 { // GDExtensionInterfaceVariantGetObjectInstanceId
        _ = self;
        return 0;
    }

    pub fn hashCompare(self: *const Variant, other: *const Variant) bool { // GDExtensionInterfaceVariantHashCompare
        _ = self;
        _ = other;
        return false;
    }

    pub fn recursiveHash(self: *const Variant, recursion_count: i64) i64 { // GDExtensionInterfaceVariantRecursiveHash
        _ = self;
        _ = recursion_count;
        return 0;
    }

    pub fn hasKey(self: *const Variant, key: *const Variant) bool { // GDExtensionInterfaceVariantHasKey
        _ = self;
        _ = key;
        return false;
    }

    pub fn hasMember(variant_type: Type, member: *const StringName) bool { // GDExtensionInterfaceVariantHasMember
        _ = variant_type;
        _ = member;
        return false;
    }

    pub fn hasMethod(self: *const Variant, method: *const StringName) bool { // GDExtensionInterfaceVariantHasMethod
        _ = self;
        _ = method;
        return false;
    }

    pub fn iterInit(self: *const Variant, iter: *Variant) bool { // GDExtensionInterfaceVariantIterInit
        _ = self;
        _ = iter;
        return false;
    }

    pub fn iterNext(self: *const Variant, iter: *Variant) bool { // GDExtensionInterfaceVariantIterNext
        _ = self;
        _ = iter;
        return false;
    }

    pub fn iterGet(self: *const Variant, iter: *Variant) Variant { // GDExtensionInterfaceVariantIterGet
        _ = self;
        _ = iter;
        return Variant{ .data = undefined };
    }
};

pub const String = extern struct {
    data: [8]u8, // Opaque data

    pub fn initWithUtf8(self: *String, text: []const u8) void { // GDExtensionInterfaceStringNewWithUtf8Chars
        _ = self;
        _ = text;
    }

    pub fn initWithUtf16(self: *String, text: []const u16) void { // GDExtensionInterfaceStringNewWithUtf16Chars
        _ = self;
        _ = text;
    }

    pub fn initWithLatin1(self: *String, text: []const u8) void { // GDExtensionInterfaceStringNewWithLatin1Chars
        _ = self;
        _ = text;
    }

    pub fn initWithLatin1AndLen(self: *String, text: []const u8, length: i64) void { // GDExtensionInterfaceStringNewWithLatin1CharsAndLen
        _ = self;
        _ = text;
        _ = length;
    }

    pub fn initWithUtf8AndLen(self: *String, text: []const u8, length: i64) void { // GDExtensionInterfaceStringNewWithUtf8CharsAndLen
        _ = self;
        _ = text;
        _ = length;
    }

    pub fn initWithUtf8AndLen2(self: *String, text: []const u8, length: i64) void { // GDExtensionInterfaceStringNewWithUtf8CharsAndLen2
        _ = self;
        _ = text;
        _ = length;
    }

    pub fn initWithUtf16AndLen(self: *String, text: []const u16, length: i64) void { // GDExtensionInterfaceStringNewWithUtf16CharsAndLen
        _ = self;
        _ = text;
        _ = length;
    }

    pub fn initWithUtf16AndLen2(self: *String, text: []const u16, length: i64, little_endian: bool) void { // GDExtensionInterfaceStringNewWithUtf16CharsAndLen2
        _ = self;
        _ = text;
        _ = length;
        _ = little_endian;
    }

    pub fn initWithUtf32(self: *String, text: []const u32) void { // GDExtensionInterfaceStringNewWithUtf32Chars
        _ = self;
        _ = text;
    }

    pub fn initWithUtf32AndLen(self: *String, text: []const u32, length: i64) void { // GDExtensionInterfaceStringNewWithUtf32CharsAndLen
        _ = self;
        _ = text;
        _ = length;
    }

    pub fn initWithWideChars(self: *String, text: [*:0]const u16) void { // GDExtensionInterfaceStringNewWithWideChars
        _ = self;
        _ = text;
    }

    pub fn initWithWideCharsAndLen(self: *String, text: [*]const u16, length: i64) void { // GDExtensionInterfaceStringNewWithWideCharsAndLen
        _ = self;
        _ = text;
        _ = length;
    }

    pub fn resize(self: *String, new_length: i64) i64 { // GDExtensionInterfaceStringResize
        _ = self;
        _ = new_length;
        return 0;
    }

    pub fn toUtf8(self: *const String, buffer: []u8) usize { // GDExtensionInterfaceStringToUtf8Chars
        _ = self;
        _ = buffer;
        return 0;
    }

    pub fn toUtf16(self: *const String, buffer: []u16) usize { // GDExtensionInterfaceStringToUtf16Chars
        _ = self;
        _ = buffer;
        return 0;
    }

    pub fn toUtf32(self: *const String, buffer: []u32) usize { // GDExtensionInterfaceStringToUtf32Chars
        _ = self;
        _ = buffer;
        return 0;
    }

    pub fn toLatin1(self: *const String, buffer: []u8) usize { // GDExtensionInterfaceStringToLatin1Chars
        _ = self;
        _ = buffer;
        return 0;
    }

    pub fn toWideChars(self: *const String, buffer: []u16) usize { // GDExtensionInterfaceStringToWideChars
        _ = self;
        _ = buffer;
        return 0;
    }

    pub fn operatorIndex(self: *String, index: i64) *u32 { // GDExtensionInterfaceStringOperatorIndex
        _ = self;
        _ = index;
        return @ptrFromInt(0);
    }

    pub fn operatorIndexConst(self: *const String, index: i64) *const u32 { // GDExtensionInterfaceStringOperatorIndexConst
        _ = self;
        _ = index;
        return @ptrFromInt(0);
    }

    pub fn operatorPlusEqString(self: *String, other: *const String) void { // GDExtensionInterfaceStringOperatorPlusEqString
        _ = self;
        _ = other;
    }

    pub fn operatorPlusEqCStr(self: *String, cstr: [*:0]const u8) void { // GDExtensionInterfaceStringOperatorPlusEqCstr
        _ = self;
        _ = cstr;
    }

    pub fn operatorPlusEqChar(self: *String, char: u32) void { // GDExtensionInterfaceStringOperatorPlusEqChar
        _ = self;
        _ = char;
    }

    pub fn operatorPlusEqWcstr(self: *String, wcstr: [*:0]const u16) void { // GDExtensionInterfaceStringOperatorPlusEqWcstr
        _ = self;
        _ = wcstr;
    }

    pub fn operatorPlusEqC32str(self: *String, c32str: [*:0]const u32) void { // GDExtensionInterfaceStringOperatorPlusEqC32str
        _ = self;
        _ = c32str;
    }
};

pub const StringName = extern struct {
    data: [8]u8, // Opaque data

    pub fn initWithUtf8(self: *StringName, text: []const u8) void { // GDExtensionInterfaceStringNameNewWithUtf8Chars
        _ = self;
        _ = text;
    }

    pub fn initWithLatin1(self: *StringName, text: []const u8, is_static: bool) void { // GDExtensionInterfaceStringNameNewWithLatin1Chars
        _ = self;
        _ = text;
        _ = is_static;
    }

    pub fn initWithUtf8AndLen(self: *StringName, text: []const u8, length: i64) void { // GDExtensionInterfaceStringNameNewWithUtf8CharsAndLen
        _ = self;
        _ = text;
        _ = length;
    }
};

pub const Array = extern struct {
    data: [8]u8,

    pub fn operatorIndex(self: *Array, index: i64) *Variant { // GDExtensionInterfaceArrayOperatorIndex
        _ = self;
        _ = index;
        return @ptrFromInt(0);
    }

    pub fn operatorIndexConst(self: *const Array, index: i64) *const Variant { // GDExtensionInterfaceArrayOperatorIndexConst
        _ = self;
        _ = index;
        return @ptrFromInt(0);
    }

    pub fn setTyped(self: *Array, element_type: Variant.Type, class_name: *const StringName, script: *const Variant) void { // GDExtensionInterfaceArraySetTyped
        _ = self;
        _ = element_type;
        _ = class_name;
        _ = script;
    }

    pub fn ref(self: *Array, other: *const Array) void { // GDExtensionInterfaceArrayRef
        _ = self;
        _ = other;
    }
};

pub const Dictionary = extern struct {
    data: [8]u8,

    pub fn operatorIndex(self: *Dictionary, key: *const Variant) *Variant { // GDExtensionInterfaceDictionaryOperatorIndex
        _ = self;
        _ = key;
        return @ptrFromInt(0);
    }

    pub fn operatorIndexConst(self: *const Dictionary, key: *const Variant) *const Variant { // GDExtensionInterfaceDictionaryOperatorIndexConst
        _ = self;
        _ = key;
        return @ptrFromInt(0);
    }

    pub fn setTyped(
        self: *Dictionary,
        key_type: Variant.Type,
        key_class_name: *const StringName,
        key_script: *const Variant,
        value_type: Variant.Type,
        value_class_name: *const StringName,
        value_script: *const Variant,
    ) void { // GDExtensionInterfaceDictionarySetTyped
        _ = self;
        _ = key_type;
        _ = key_class_name;
        _ = key_script;
        _ = value_type;
        _ = value_class_name;
        _ = value_script;
    }
};

pub const Callable = extern struct {
    data: [16]u8,

    // Custom callable function pointers
    pub const CustomCall = TODO; // GDExtensionCallableCustomCall
    pub const CustomIsValid = TODO; // GDExtensionCallableCustomIsValid
    pub const CustomFree = TODO; // GDExtensionCallableCustomFree
    pub const CustomHash = TODO; // GDExtensionCallableCustomHash
    pub const CustomEqual = TODO; // GDExtensionCallableCustomEqual
    pub const CustomLessThan = TODO; // GDExtensionCallableCustomLessThan
    pub const CustomToString = TODO; // GDExtensionCallableCustomToString
    pub const CustomGetArgumentCount = TODO; // GDExtensionCallableCustomGetArgumentCount

    pub const CustomInfo = struct {
        callable_userdata: ?*anyopaque,
        token: ?*anyopaque,
        object_id: u64,
        call_func: ?CustomCall,
        is_valid_func: ?CustomIsValid,
        free_func: ?CustomFree,
        hash_func: ?CustomHash,
        equal_func: ?CustomEqual,
        less_than_func: ?CustomLessThan,
        to_string_func: ?CustomToString,
        get_argument_count_func: ?CustomGetArgumentCount,
    };

    pub fn initCustom(self: *Callable, info: *const CustomInfo) void { // GDExtensionInterfaceCallableCustomCreate
        _ = self;
        _ = info;
    }

    pub fn initCustom2(self: *Callable, info: *const CustomInfo) void { // GDExtensionInterfaceCallableCustomCreate2
        _ = self;
        _ = info;
    }

    pub fn getUserData(self: *const Callable, token: ?*anyopaque) ?*anyopaque { // GDExtensionInterfaceCallableCustomGetUserData
        _ = self;
        _ = token;
        return null;
    }
};

pub const Object = extern struct {
    ptr: ?*anyopaque,

    pub fn destroy(self: *Object) void { // GDExtensionInterfaceObjectDestroy
        _ = self;
    }

    pub fn getClassName(self: *const Object, library: ?*anyopaque) StringName { // GDExtensionInterfaceObjectGetClassName
        _ = self;
        _ = library;
        return StringName{ .data = undefined };
    }

    pub fn getInstanceId(self: *const Object) u64 { // GDExtensionInterfaceObjectGetInstanceId
        _ = self;
        return 0;
    }

    pub fn castTo(self: *const Object, class_tag: ?*anyopaque) ?*Object { // GDExtensionInterfaceObjectCastTo
        _ = self;
        _ = class_tag;
        return null;
    }

    pub fn callScriptMethod(self: *Object, method: *const StringName, args: []const *const Variant) Variant { // GDExtensionInterfaceObjectCallScriptMethod
        _ = self;
        _ = method;
        _ = args;
        return Variant{ .data = undefined };
    }

    pub fn hasScriptMethod(self: *const Object, method: *const StringName) bool { // GDExtensionInterfaceObjectHasScriptMethod
        _ = self;
        _ = method;
        return false;
    }

    pub fn setInstance(self: *Object, class_name: *const StringName, instance: ?*anyopaque) void { // GDExtensionInterfaceObjectSetInstance
        _ = self;
        _ = class_name;
        _ = instance;
    }

    pub fn getScriptInstance(self: *const Object, language: *Object) ?*anyopaque { // GDExtensionInterfaceObjectGetScriptInstance
        _ = self;
        _ = language;
        return null;
    }

    pub fn fromInstanceId(instance_id: u64) ?*Object { // GDExtensionInterfaceObjectGetInstanceFromId
        _ = instance_id;
        return null;
    }

    pub fn getInstanceBinding(self: *Object, token: ?*anyopaque, callbacks: ?*const InstanceBindingCallbacks) ?*anyopaque { // GDExtensionInterfaceObjectGetInstanceBinding
        _ = self;
        _ = token;
        _ = callbacks;
        return null;
    }

    pub fn setInstanceBinding(self: *Object, token: ?*anyopaque, binding: ?*anyopaque, callbacks: ?*const InstanceBindingCallbacks) void { // GDExtensionInterfaceObjectSetInstanceBinding
        _ = self;
        _ = token;
        _ = binding;
        _ = callbacks;
    }

    pub fn freeInstanceBinding(self: *Object, token: ?*anyopaque) void { // GDExtensionInterfaceObjectFreeInstanceBinding
        _ = self;
        _ = token;
    }
};

pub const Ref = extern struct {
    data: [8]u8,

    pub fn getObject(self: *const Ref) ?*Object { // GDExtensionInterfaceRefGetObject
        _ = self;
        return null;
    }

    pub fn setObject(self: *Ref, object: ?*Object) void { // GDExtensionInterfaceRefSetObject
        _ = self;
        _ = object;
    }
};

pub const MethodBind = opaque {
    pub fn call(self: *MethodBind, object: *Object, args: []const *const Variant) Variant { // GDExtensionInterfaceObjectMethodBindCall
        _ = self;
        _ = object;
        _ = args;
        return Variant{ .data = undefined };
    }

    pub fn ptrCall(self: *MethodBind, object: *Object, args: []const ?*const anyopaque, ret: ?*anyopaque) void { // GDExtensionInterfaceObjectMethodBindPtrcall
        _ = self;
        _ = object;
        _ = args;
        _ = ret;
    }
};

// Packed Arrays - Only C interface functions
pub const PackedByteArray = extern struct {
    data: [16]u8,

    pub fn operatorIndex(self: *PackedByteArray, index: i64) *u8 { // GDExtensionInterfacePackedByteArrayOperatorIndex
        _ = self;
        _ = index;
        return @ptrFromInt(0);
    }

    pub fn operatorIndexConst(self: *const PackedByteArray, index: i64) *const u8 { // GDExtensionInterfacePackedByteArrayOperatorIndexConst
        _ = self;
        _ = index;
        return @ptrFromInt(0);
    }
};

pub const PackedInt32Array = extern struct {
    data: [16]u8,

    pub fn operatorIndex(self: *PackedInt32Array, index: i64) *i32 { // GDExtensionInterfacePackedInt32ArrayOperatorIndex
        _ = self;
        _ = index;
        return @ptrFromInt(0);
    }

    pub fn operatorIndexConst(self: *const PackedInt32Array, index: i64) *const i32 { // GDExtensionInterfacePackedInt32ArrayOperatorIndexConst
        _ = self;
        _ = index;
        return @ptrFromInt(0);
    }
};

pub const PackedInt64Array = extern struct {
    data: [16]u8,

    pub fn operatorIndex(self: *PackedInt64Array, index: i64) *i64 { // GDExtensionInterfacePackedInt64ArrayOperatorIndex
        _ = self;
        _ = index;
        return @ptrFromInt(0);
    }

    pub fn operatorIndexConst(self: *const PackedInt64Array, index: i64) *const i64 { // GDExtensionInterfacePackedInt64ArrayOperatorIndexConst
        _ = self;
        _ = index;
        return @ptrFromInt(0);
    }
};

pub const PackedFloat32Array = extern struct {
    data: [16]u8,

    pub fn operatorIndex(self: *PackedFloat32Array, index: i64) *f32 { // GDExtensionInterfacePackedFloat32ArrayOperatorIndex
        _ = self;
        _ = index;
        return @ptrFromInt(0);
    }

    pub fn operatorIndexConst(self: *const PackedFloat32Array, index: i64) *const f32 { // GDExtensionInterfacePackedFloat32ArrayOperatorIndexConst
        _ = self;
        _ = index;
        return @ptrFromInt(0);
    }
};

pub const PackedFloat64Array = extern struct {
    data: [16]u8,

    pub fn operatorIndex(self: *PackedFloat64Array, index: i64) *f64 { // GDExtensionInterfacePackedFloat64ArrayOperatorIndex
        _ = self;
        _ = index;
        return @ptrFromInt(0);
    }

    pub fn operatorIndexConst(self: *const PackedFloat64Array, index: i64) *const f64 { // GDExtensionInterfacePackedFloat64ArrayOperatorIndexConst
        _ = self;
        _ = index;
        return @ptrFromInt(0);
    }
};

pub const PackedStringArray = extern struct {
    data: [16]u8,

    pub fn operatorIndex(self: *PackedStringArray, index: i64) *String { // GDExtensionInterfacePackedStringArrayOperatorIndex
        _ = self;
        _ = index;
        return @ptrFromInt(0);
    }

    pub fn operatorIndexConst(self: *const PackedStringArray, index: i64) *const String { // GDExtensionInterfacePackedStringArrayOperatorIndexConst
        _ = self;
        _ = index;
        return @ptrFromInt(0);
    }
};

pub const PackedVector2Array = extern struct {
    data: [16]u8,

    pub fn operatorIndex(self: *PackedVector2Array, index: i64) *Vector2 { // GDExtensionInterfacePackedVector2ArrayOperatorIndex
        _ = self;
        _ = index;
        return @ptrFromInt(0);
    }

    pub fn operatorIndexConst(self: *const PackedVector2Array, index: i64) *const Vector2 { // GDExtensionInterfacePackedVector2ArrayOperatorIndexConst
        _ = self;
        _ = index;
        return @ptrFromInt(0);
    }
};

pub const PackedVector3Array = extern struct {
    data: [16]u8,

    pub fn operatorIndex(self: *PackedVector3Array, index: i64) *Vector3 { // GDExtensionInterfacePackedVector3ArrayOperatorIndex
        _ = self;
        _ = index;
        return @ptrFromInt(0);
    }

    pub fn operatorIndexConst(self: *const PackedVector3Array, index: i64) *const Vector3 { // GDExtensionInterfacePackedVector3ArrayOperatorIndexConst
        _ = self;
        _ = index;
        return @ptrFromInt(0);
    }
};

pub const PackedVector4Array = extern struct {
    data: [16]u8,

    pub fn operatorIndex(self: *PackedVector4Array, index: i64) *Vector4 { // GDExtensionInterfacePackedVector4ArrayOperatorIndex
        _ = self;
        _ = index;
        return @ptrFromInt(0);
    }

    pub fn operatorIndexConst(self: *const PackedVector4Array, index: i64) *const Vector4 { // GDExtensionInterfacePackedVector4ArrayOperatorIndexConst
        _ = self;
        _ = index;
        return @ptrFromInt(0);
    }
};

pub const PackedColorArray = extern struct {
    data: [16]u8,

    pub fn operatorIndex(self: *PackedColorArray, index: i64) *Color { // GDExtensionInterfacePackedColorArrayOperatorIndex
        _ = self;
        _ = index;
        return @ptrFromInt(0);
    }

    pub fn operatorIndexConst(self: *const PackedColorArray, index: i64) *const Color { // GDExtensionInterfacePackedColorArrayOperatorIndexConst
        _ = self;
        _ = index;
        return @ptrFromInt(0);
    }
};

// Math types - No C interface functions, just data structures
pub const Color = extern struct {
    r: f32,
    g: f32,
    b: f32,
    a: f32,
};

pub const Vector2 = extern struct {
    x: f32,
    y: f32,
};

pub const Vector2i = extern struct {
    x: i32,
    y: i32,
};

pub const Vector3 = extern struct {
    x: f32,
    y: f32,
    z: f32,
};

pub const Vector3i = extern struct {
    x: i32,
    y: i32,
    z: i32,
};

pub const Vector4 = extern struct {
    x: f32,
    y: f32,
    z: f32,
    w: f32,
};

pub const Vector4i = extern struct {
    x: i32,
    y: i32,
    z: i32,
    w: i32,
};

pub const Rect2 = extern struct {
    position: Vector2,
    size: Vector2,
};

pub const Rect2i = extern struct {
    position: Vector2i,
    size: Vector2i,
};

pub const Transform2D = extern struct {
    columns: [3]Vector2,
};

pub const Plane = extern struct {
    normal: Vector3,
    d: f32,
};

pub const Quaternion = extern struct {
    x: f32,
    y: f32,
    z: f32,
    w: f32,
};

pub const AABB = extern struct {
    position: Vector3,
    size: Vector3,
};

pub const Basis = extern struct {
    rows: [3]Vector3,
};

pub const Transform3D = extern struct {
    basis: Basis,
    origin: Vector3,
};

pub const Projection = extern struct {
    columns: [4]Vector4,
};

pub const RID = extern struct {
    id: u64,
};

pub const NodePath = extern struct {
    data: [8]u8,
};

pub const Signal = extern struct {
    data: [16]u8,
};

// File Access - No methods exposed in clean interface, just opaque type
pub const FileAccess = opaque {
    pub fn getBuffer(self: *const FileAccess, buffer: []u8) u64 { // GDExtensionInterfaceFileAccessGetBuffer
        _ = self;
        _ = buffer;
        return 0;
    }

    pub fn storeBuffer(self: *FileAccess, buffer: []const u8) void { // GDExtensionInterfaceFileAccessStoreBuffer
        _ = self;
        _ = buffer;
    }
};

// Script Instance support structures
pub const ScriptInstance = struct {
    // ScriptInstance function pointer types
    pub const SetFunc = TODO; // GDExtensionScriptInstanceSet
    pub const GetFunc = TODO; // GDExtensionScriptInstanceGet
    pub const GetPropertyListFunc = TODO; // GDExtensionScriptInstanceGetPropertyList
    pub const FreePropertyListFunc = TODO; // GDExtensionScriptInstanceFreePropertyList
    pub const FreePropertyList2Func = TODO; // GDExtensionScriptInstanceFreePropertyList2
    pub const GetClassCategoryFunc = TODO; // GDExtensionScriptInstanceGetClassCategory
    pub const GetPropertyTypeFunc = TODO; // GDExtensionScriptInstanceGetPropertyType
    pub const ValidatePropertyFunc = TODO; // GDExtensionScriptInstanceValidateProperty
    pub const PropertyCanRevertFunc = TODO; // GDExtensionScriptInstancePropertyCanRevert
    pub const PropertyGetRevertFunc = TODO; // GDExtensionScriptInstancePropertyGetRevert
    pub const GetOwnerFunc = TODO; // GDExtensionScriptInstanceGetOwner
    pub const PropertyStateAddFunc = TODO; // GDExtensionScriptInstancePropertyStateAdd
    pub const GetPropertyStateFunc = TODO; // GDExtensionScriptInstanceGetPropertyState
    pub const GetMethodListFunc = TODO; // GDExtensionScriptInstanceGetMethodList
    pub const FreeMethodListFunc = TODO; // GDExtensionScriptInstanceFreeMethodList
    pub const FreeMethodList2Func = TODO; // GDExtensionScriptInstanceFreeMethodList2
    pub const HasMethodFunc = TODO; // GDExtensionScriptInstanceHasMethod
    pub const GetMethodArgumentCountFunc = TODO; // GDExtensionScriptInstanceGetMethodArgumentCount
    pub const CallFunc = TODO; // GDExtensionScriptInstanceCall
    pub const NotificationFunc = TODO; // GDExtensionScriptInstanceNotification
    pub const Notification2Func = TODO; // GDExtensionScriptInstanceNotification2
    pub const ToStringFunc = TODO; // GDExtensionScriptInstanceToString
    pub const RefCountIncrementedFunc = TODO; // GDExtensionScriptInstanceRefCountIncremented
    pub const RefCountDecrementedFunc = TODO; // GDExtensionScriptInstanceRefCountDecremented
    pub const GetScriptFunc = TODO; // GDExtensionScriptInstanceGetScript
    pub const IsPlaceholderFunc = TODO; // GDExtensionScriptInstanceIsPlaceholder
    pub const GetLanguageFunc = TODO; // GDExtensionScriptInstanceGetLanguage
    pub const FreeFunc = TODO; // GDExtensionScriptInstanceFree

    pub const PropertyInfo = extern struct {
        type: Variant.Type,
        name: StringName,
        class_name: StringName,
        hint: u32,
        hint_string: String,
        usage: u32,
    };

    pub const MethodInfo = extern struct {
        name: StringName,
        return_value: PropertyInfo,
        flags: u32,
        id: i32,
        argument_count: u32,
        arguments: ?[*]PropertyInfo,
        default_argument_count: u32,
        default_arguments: ?[*]*Variant,
    };

    pub const Info = extern struct {
        set_func: ?SetFunc,
        get_func: ?GetFunc,
        get_property_list_func: ?GetPropertyListFunc,
        free_property_list_func: ?FreePropertyListFunc,
        property_can_revert_func: ?PropertyCanRevertFunc,
        property_get_revert_func: ?PropertyGetRevertFunc,
        get_owner_func: ?GetOwnerFunc,
        get_property_state_func: ?GetPropertyStateFunc,
        get_method_list_func: ?GetMethodListFunc,
        free_method_list_func: ?FreeMethodListFunc,
        get_property_type_func: ?GetPropertyTypeFunc,
        has_method_func: ?HasMethodFunc,
        call_func: ?CallFunc,
        notification_func: ?NotificationFunc,
        to_string_func: ?ToStringFunc,
        refcount_incremented_func: ?RefCountIncrementedFunc,
        refcount_decremented_func: ?RefCountDecrementedFunc,
        get_script_func: ?GetScriptFunc,
        is_placeholder_func: ?IsPlaceholderFunc,
        set_fallback_func: ?SetFunc,
        get_fallback_func: ?GetFunc,
        get_language_func: ?GetLanguageFunc,
        free_func: ?FreeFunc,
    };

    pub fn create(info: *const Info, instance_data: ?*anyopaque) ?*anyopaque { // GDExtensionInterfaceScriptInstanceCreate
        _ = info;
        _ = instance_data;
        return null;
    }

    pub fn create2(info: *const Info, instance_data: ?*anyopaque) ?*anyopaque { // GDExtensionInterfaceScriptInstanceCreate2
        _ = info;
        _ = instance_data;
        return null;
    }

    pub fn create3(info: *const Info, instance_data: ?*anyopaque) ?*anyopaque { // GDExtensionInterfaceScriptInstanceCreate3
        _ = info;
        _ = instance_data;
        return null;
    }

    pub fn createPlaceholder(language: *Object, script: *Object, owner: *Object) ?*anyopaque { // GDExtensionInterfacePlaceHolderScriptInstanceCreate
        _ = language;
        _ = script;
        _ = owner;
        return null;
    }

    pub fn updatePlaceholder(placeholder: ?*anyopaque, properties: ?*const anyopaque, values: ?*const anyopaque) void { // GDExtensionInterfacePlaceHolderScriptInstanceUpdate
        _ = placeholder;
        _ = properties;
        _ = values;
    }
};

pub const CallError = extern struct {
    @"error": CallErrorType,
    argument: i32,
    expected: i32,
};

pub const CallErrorType = enum(u32) {
    ok = 0,
    invalid_method = 1,
    invalid_argument = 2,
    too_many_arguments = 3,
    too_few_arguments = 4,
    instance_is_null = 5,
    method_not_const = 6,
};
// Class constructor
pub const Constructor = TODO; // GDExtensionClassConstructor

// Class function pointer types
pub const ClassSetFunc = TODO; // GDExtensionClassSet
pub const ClassGetFunc = TODO; // GDExtensionClassGet
pub const ClassGetRIDFunc = TODO; // GDExtensionClassGetRID
pub const ClassGetPropertyListFunc = TODO; // GDExtensionClassGetPropertyList
pub const ClassFreePropertyListFunc = TODO; // GDExtensionClassFreePropertyList
pub const ClassFreePropertyList2Func = TODO; // GDExtensionClassFreePropertyList2
pub const ClassPropertyCanRevertFunc = TODO; // GDExtensionClassPropertyCanRevert
pub const ClassPropertyGetRevertFunc = TODO; // GDExtensionClassPropertyGetRevert
pub const ClassValidatePropertyFunc = TODO; // GDExtensionClassValidateProperty
pub const ClassNotificationFunc = TODO; // GDExtensionClassNotification
pub const ClassNotification2Func = TODO; // GDExtensionClassNotification2
pub const ClassToStringFunc = TODO; // GDExtensionClassToString
pub const ClassReferenceFunc = TODO; // GDExtensionClassReference
pub const ClassUnreferenceFunc = TODO; // GDExtensionClassUnreference
pub const ClassCallVirtualFunc = TODO; // GDExtensionClassCallVirtual
pub const ClassCreateInstanceFunc = TODO; // GDExtensionClassCreateInstance
pub const ClassCreateInstance2Func = TODO; // GDExtensionClassCreateInstance2
pub const ClassFreeInstanceFunc = TODO; // GDExtensionClassFreeInstance
pub const ClassRecreateInstanceFunc = TODO; // GDExtensionClassRecreateInstance
pub const ClassGetVirtualFunc = TODO; // GDExtensionClassGetVirtual
pub const ClassGetVirtual2Func = TODO; // GDExtensionClassGetVirtual2
pub const ClassGetVirtualCallDataFunc = TODO; // GDExtensionClassGetVirtualCallData
pub const ClassGetVirtualCallData2Func = TODO; // GDExtensionClassGetVirtualCallData2
pub const ClassCallVirtualWithDataFunc = TODO; // GDExtensionClassCallVirtualWithData

pub const ClassCreationInfo = extern struct {
    is_virtual: bool,
    is_abstract: bool,
    set_func: ?ClassSetFunc,
    get_func: ?ClassGetFunc,
    get_property_list_func: ?ClassGetPropertyListFunc,
    free_property_list_func: ?ClassFreePropertyListFunc,
    property_can_revert_func: ?PropertyCanRevertFunc,
    property_get_revert_func: ?PropertyGetRevertFunc,
    notification_func: ?NotificationFunc,
    to_string_func: ?ToStringFunc,
    reference_func: ?ReferenceFunc,
    unreference_func: ?UnreferenceFunc,
    create_instance_func: ?CreateInstanceFunc,
    free_instance_func: ?FreeInstanceFunc,
    get_virtual_func: ?GetVirtualFunc,
    get_rid_func: ?GetRIDFunc,
    class_userdata: ?*anyopaque,
};

pub const ClassMethodInfo = extern struct {
    // Class method function pointer types
    pub const MethodCall = TODO; // GDExtensionClassMethodCall
    pub const MethodValidatedCall = TODO; // GDExtensionClassMethodValidatedCall
    pub const MethodPtrCall = TODO; // GDExtensionClassMethodPtrCall

    name: StringName,
    method_userdata: ?*anyopaque,
    call_func: ?MethodCall,
    ptrcall_func: ?MethodPtrCall,
    method_flags: u32,
    has_return_value: bool,
    return_value_info: ?*ScriptInstance.PropertyInfo,
    return_value_metadata: u32,
    argument_count: u32,
    arguments_info: ?[*]ScriptInstance.PropertyInfo,
    arguments_metadata: ?[*]u32,
    default_argument_count: u32,
    default_arguments: ?[*]*Variant,
};

pub const InstanceBindingCallbacks = extern struct {
    // Instance binding function pointer types
    pub const CreateCallback = TODO; // GDExtensionInstanceBindingCreateCallback
    pub const FreeCallback = TODO; // GDExtensionInstanceBindingFreeCallback
    pub const ReferenceCallback = TODO; // GDExtensionInstanceBindingReferenceCallback

    create_callback: ?CreateCallback,
    free_callback: ?FreeCallback,
    reference_callback: ?ReferenceCallback,
};

pub const InitializationLevel = enum(u32) {
    core = 0,
    servers = 1,
    scene = 2,
    editor = 3,
    max = 4,
};

pub const Initialization = extern struct {
    minimum_initialization_level: InitializationLevel,
    userdata: ?*anyopaque,
    initialize: ?*const fn () void,
    deinitialize: ?*const fn () void,
};

// Interface function to get function pointers
pub const InterfaceGetProcAddress = TODO; // GDExtensionInterfaceGetProcAddress

// Function pointer type
pub const FunctionPtr = TODO; // GDExtensionInterfaceFunctionPtr

// Main entry point function type
pub const InitializationFunction = *const fn (get_proc_address: InterfaceGetProcAddress, library: ?*anyopaque, initialization: *Initialization) bool;

// ClassDB API - Only actual C interface functions
pub const ClassDB = struct {
    pub fn constructObject(class_name: *const StringName) ?*Object { // GDExtensionInterfaceClassdbConstructObject
        _ = class_name;
        return null;
    }

    pub fn constructObject2(class_name: *const StringName) ?*Object { // GDExtensionInterfaceClassdbConstructObject2
        _ = class_name;
        return null;
    }

    pub fn getMethodBind(class_name: *const StringName, method_name: *const StringName, hash: i64) ?*MethodBind { // GDExtensionInterfaceClassdbGetMethodBind
        _ = class_name;
        _ = method_name;
        _ = hash;
        return null;
    }

    pub fn getClassTag(class_name: *const StringName) ?*anyopaque { // GDExtensionInterfaceClassdbGetClassTag
        _ = class_name;
        return null;
    }

    pub fn registerClass(library: ?*anyopaque, class_name: *const StringName, parent_class_name: *const StringName, info: *const ClassCreationInfo) void { // GDExtensionInterfaceClassdbRegisterExtensionClass
        _ = library;
        _ = class_name;
        _ = parent_class_name;
        _ = info;
    }

    pub fn registerClass2(library: ?*anyopaque, class_name: *const StringName, parent_class_name: *const StringName, info: *const ClassCreationInfo) void { // GDExtensionInterfaceClassdbRegisterExtensionClass2
        _ = library;
        _ = class_name;
        _ = parent_class_name;
        _ = info;
    }

    pub fn registerClass3(library: ?*anyopaque, class_name: *const StringName, parent_class_name: *const StringName, info: *const ClassCreationInfo) void { // GDExtensionInterfaceClassdbRegisterExtensionClass3
        _ = library;
        _ = class_name;
        _ = parent_class_name;
        _ = info;
    }

    pub fn registerClass4(library: ?*anyopaque, class_name: *const StringName, parent_class_name: *const StringName, info: *const ClassCreationInfo) void { // GDExtensionInterfaceClassdbRegisterExtensionClass4
        _ = library;
        _ = class_name;
        _ = parent_class_name;
        _ = info;
    }

    pub fn unregisterClass(library: ?*anyopaque, class_name: *const StringName) void { // GDExtensionInterfaceClassdbUnregisterExtensionClass
        _ = library;
        _ = class_name;
    }

    pub fn registerMethod(library: ?*anyopaque, class_name: *const StringName, method_info: *const ClassMethodInfo) void { // GDExtensionInterfaceClassdbRegisterExtensionClassMethod
        _ = library;
        _ = class_name;
        _ = method_info;
    }

    pub fn registerSignal(library: ?*anyopaque, class_name: *const StringName, signal_name: *const StringName, argument_info: ?[*]const ScriptInstance.PropertyInfo, argument_count: i64) void { // GDExtensionInterfaceClassdbRegisterExtensionClassSignal
        _ = library;
        _ = class_name;
        _ = signal_name;
        _ = argument_info;
        _ = argument_count;
    }

    pub fn registerProperty(library: ?*anyopaque, class_name: *const StringName, property_info: *const ScriptInstance.PropertyInfo, setter: *const StringName, getter: *const StringName) void { // GDExtensionInterfaceClassdbRegisterExtensionClassProperty
        _ = library;
        _ = class_name;
        _ = property_info;
        _ = setter;
        _ = getter;
    }

    pub fn registerPropertyIndexed(library: ?*anyopaque, class_name: *const StringName, property_info: *const ScriptInstance.PropertyInfo, setter: *const StringName, getter: *const StringName, index: i64) void { // GDExtensionInterfaceClassdbRegisterExtensionClassPropertyIndexed
        _ = library;
        _ = class_name;
        _ = property_info;
        _ = setter;
        _ = getter;
        _ = index;
    }

    pub fn registerPropertyGroup(library: ?*anyopaque, class_name: *const StringName, group_name: *const String, prefix: *const String) void { // GDExtensionInterfaceClassdbRegisterExtensionClassPropertyGroup
        _ = library;
        _ = class_name;
        _ = group_name;
        _ = prefix;
    }

    pub fn registerPropertySubgroup(library: ?*anyopaque, class_name: *const StringName, subgroup_name: *const String, prefix: *const String) void { // GDExtensionInterfaceClassdbRegisterExtensionClassPropertySubgroup
        _ = library;
        _ = class_name;
        _ = subgroup_name;
        _ = prefix;
    }

    pub fn registerVirtualMethod(library: ?*anyopaque, class_name: *const StringName, method_info: *const ClassMethodInfo) void { // GDExtensionInterfaceClassdbRegisterExtensionClassVirtualMethod
        _ = library;
        _ = class_name;
        _ = method_info;
    }

    pub fn registerIntegerConstant(library: ?*anyopaque, class_name: *const StringName, enum_name: *const StringName, constant_name: *const StringName, constant_value: i64, is_bitfield: bool) void { // GDExtensionInterfaceClassdbRegisterExtensionClassIntegerConstant
        _ = library;
        _ = class_name;
        _ = enum_name;
        _ = constant_name;
        _ = constant_value;
        _ = is_bitfield;
    }
};

// Memory management API
pub const mem = struct {
    pub fn alloc(bytes: usize) ?*anyopaque { // GDExtensionInterfaceMemAlloc
        _ = bytes;
        return null;
    }

    pub fn free(ptr: ?*anyopaque) void { // GDExtensionInterfaceMemFree
        _ = ptr;
    }

    pub fn realloc(ptr: ?*anyopaque, bytes: usize) ?*anyopaque { // GDExtensionInterfaceMemRealloc
        _ = ptr;
        _ = bytes;
        return null;
    }
};

// Print/error API
pub const print = struct {
    pub fn err(description: [*:0]const u8, function: [*:0]const u8, file: [*:0]const u8, line: i32, editor_notify: bool) void { // GDExtensionInterfacePrintError
        _ = description;
        _ = function;
        _ = file;
        _ = line;
        _ = editor_notify;
    }

    pub fn errWithMessage(description: [*:0]const u8, message: [*:0]const u8, function: [*:0]const u8, file: [*:0]const u8, line: i32, editor_notify: bool) void { // GDExtensionInterfacePrintErrorWithMessage
        _ = description;
        _ = message;
        _ = function;
        _ = file;
        _ = line;
        _ = editor_notify;
    }

    pub fn warning(description: [*:0]const u8, function: [*:0]const u8, file: [*:0]const u8, line: i32, editor_notify: bool) void { // GDExtensionInterfacePrintWarning
        _ = description;
        _ = function;
        _ = file;
        _ = line;
        _ = editor_notify;
    }

    pub fn warningWithMessage(description: [*:0]const u8, message: [*:0]const u8, function: [*:0]const u8, file: [*:0]const u8, line: i32, editor_notify: bool) void { // GDExtensionInterfacePrintWarningWithMessage
        _ = description;
        _ = message;
        _ = function;
        _ = file;
        _ = line;
        _ = editor_notify;
    }

    pub fn scriptError(description: [*:0]const u8, function: [*:0]const u8, file: [*:0]const u8, line: i32, editor_notify: bool) void { // GDExtensionInterfacePrintScriptError
        _ = description;
        _ = function;
        _ = file;
        _ = line;
        _ = editor_notify;
    }

    pub fn scriptErrorWithMessage(description: [*:0]const u8, message: [*:0]const u8, function: [*:0]const u8, file: [*:0]const u8, line: i32, editor_notify: bool) void { // GDExtensionInterfacePrintScriptErrorWithMessage
        _ = description;
        _ = message;
        _ = function;
        _ = file;
        _ = line;
        _ = editor_notify;
    }
};

// Version info
pub const Version = extern struct {
    major: u32,
    minor: u32,
    patch: u32,
    string: [*:0]const u8,
};

pub fn getVersion() Version { // GDExtensionInterfaceGetGodotVersion
    return Version{ .major = 0, .minor = 0, .patch = 0, .string = "" };
}

pub fn getLibraryPath(library: ?*anyopaque) String { // GDExtensionInterfaceGetLibraryPath
    _ = library;
    return String{ .data = undefined };
}

// Worker Thread Pool
pub const WorkerThreadPool = opaque {
    pub fn addTask(self: *WorkerThreadPool, func: *const fn (?*anyopaque) void, userdata: ?*anyopaque, high_priority: bool, description: *const String) void { // GDExtensionInterfaceWorkerThreadPoolAddNativeTask
        _ = self;
        _ = func;
        _ = userdata;
        _ = high_priority;
        _ = description;
    }

    pub fn addGroupTask(self: *WorkerThreadPool, func: *const fn (?*anyopaque, u32) void, userdata: ?*anyopaque, elements: i32, tasks: i32, high_priority: bool, description: *const String) void { // GDExtensionInterfaceWorkerThreadPoolAddNativeGroupTask
        _ = self;
        _ = func;
        _ = userdata;
        _ = elements;
        _ = tasks;
        _ = high_priority;
        _ = description;
    }
};

// Global singleton access
pub fn getSingleton(name: *const StringName) ?*Object { // GDExtensionInterfaceGlobalGetSingleton
    _ = name;
    return null;
}

// Native struct size
pub fn getNativeStructSize(name: *const StringName) usize { // GDExtensionInterfaceGetNativeStructSize
    _ = name;
    return 0;
}

// Variant type name
pub fn getVariantTypeName(variant_type: Variant.Type) String { // GDExtensionInterfaceVariantGetTypeName
    _ = variant_type;
    return String{ .data = undefined };
}

// Utility functions
pub fn getUtilityFunction(name: *const StringName, hash: i64) ?*const fn () void { // GDExtensionInterfaceVariantGetPtrUtilityFunction
    _ = name;
    _ = hash;
    return null;
}

// Constructor/destructor access
pub fn getVariantConstructor(variant_type: Variant.Type, constructor_index: i32) ?*const fn () void { // GDExtensionInterfaceVariantGetPtrConstructor
    _ = variant_type;
    _ = constructor_index;
    return null;
}

pub fn getVariantDestructor(variant_type: Variant.Type) ?*const fn () void { // GDExtensionInterfaceVariantGetPtrDestructor
    _ = variant_type;
    return null;
}

// Method binds
pub fn getVariantBuiltinMethod(variant_type: Variant.Type, method: *const StringName, hash: i64) ?*const fn () void { // GDExtensionInterfaceVariantGetPtrBuiltinMethod
    _ = variant_type;
    _ = method;
    _ = hash;
    return null;
}

// Variant operators
pub fn getVariantOperatorEvaluator(op: Variant.Operator, type_a: Variant.Type, type_b: Variant.Type) ?*const fn () void { // GDExtensionInterfaceVariantGetPtrOperatorEvaluator
    _ = op;
    _ = type_a;
    _ = type_b;
    return null;
}

// Property getters/setters
pub fn getVariantGetter(variant_type: Variant.Type, property: *const StringName) ?*const fn () void { // GDExtensionInterfaceVariantGetPtrGetter
    _ = variant_type;
    _ = property;
    return null;
}

pub fn getVariantSetter(variant_type: Variant.Type, property: *const StringName) ?*const fn () void { // GDExtensionInterfaceVariantGetPtrSetter
    _ = variant_type;
    _ = property;
    return null;
}

// Indexed getters/setters
pub fn getVariantIndexedGetter(variant_type: Variant.Type) ?*const fn () void { // GDExtensionInterfaceVariantGetPtrIndexedGetter
    _ = variant_type;
    return null;
}

pub fn getVariantIndexedSetter(variant_type: Variant.Type) ?*const fn () void { // GDExtensionInterfaceVariantGetPtrIndexedSetter
    _ = variant_type;
    return null;
}

// Keyed getters/setters
pub fn getVariantKeyedGetter(variant_type: Variant.Type) ?*const fn () void { // GDExtensionInterfaceVariantGetPtrKeyedGetter
    _ = variant_type;
    return null;
}

pub fn getVariantKeyedSetter(variant_type: Variant.Type) ?*const fn () void { // GDExtensionInterfaceVariantGetPtrKeyedSetter
    _ = variant_type;
    return null;
}

pub fn getVariantKeyedChecker(variant_type: Variant.Type) ?*const fn () void { // GDExtensionInterfaceVariantGetPtrKeyedChecker
    _ = variant_type;
    return null;
}

// Type conversions
pub fn getVariantFromTypeConstructor(variant_type: Variant.Type) ?*const fn () void { // GDExtensionInterfaceGetVariantFromTypeConstructor
    _ = variant_type;
    return null;
}

pub fn getTypeFromVariantConstructor(variant_type: Variant.Type) ?*const fn () void { // GDExtensionInterfaceGetVariantToTypeConstructor
    _ = variant_type;
    return null;
}

pub fn getVariantGetInternalPtrFunc(variant_type: Variant.Type) ?*const fn () void { // GDExtensionInterfaceGetVariantGetInternalPtrFunc
    _ = variant_type;
    return null;
}

// Editor integration
pub const editor = struct {
    pub fn addPlugin(class_name: *const StringName) void { // GDExtensionInterfaceEditorAddPlugin
        _ = class_name;
    }

    pub fn removePlugin(class_name: *const StringName) void { // GDExtensionInterfaceEditorRemovePlugin
        _ = class_name;
    }

    pub fn loadHelpXmlFromUtf8(data: [*:0]const u8) void { // GDExtensionsInterfaceEditorHelpLoadXmlFromUtf8Chars
        _ = data;
    }

    pub fn loadHelpXmlFromUtf8AndLen(data: [*]const u8, size: i64) void { // GDExtensionsInterfaceEditorHelpLoadXmlFromUtf8CharsAndLen
        _ = data;
        _ = size;
    }
};

// XML Parser
pub const XMLParser = opaque {
    pub fn openBuffer(self: *XMLParser, buffer: []const u8) void { // GDExtensionInterfaceXmlParserOpenBuffer
        _ = self;
        _ = buffer;
    }
};

// Image
pub const Image = opaque {
    pub fn ptrw(self: *Image) [*]u8 { // GDExtensionInterfaceImagePtrw
        _ = self;
        return @ptrFromInt(0);
    }

    pub fn ptr(self: *const Image) [*]const u8 { // GDExtensionInterfaceImagePtr
        _ = self;
        return @ptrFromInt(0);
    }
};

test "mapped all functions" {}
