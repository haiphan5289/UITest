#if TARGET_OS_SIMULATOR
// Generated by Apple Swift version 5.5 (swiftlang-1300.0.29.102 clang-1300.0.28.1)
#ifndef GOOIDSDK_SWIFT_H
#define GOOIDSDK_SWIFT_H
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wgcc-compat"

#if !defined(__has_include)
# define __has_include(x) 0
#endif
#if !defined(__has_attribute)
# define __has_attribute(x) 0
#endif
#if !defined(__has_feature)
# define __has_feature(x) 0
#endif
#if !defined(__has_warning)
# define __has_warning(x) 0
#endif

#if __has_include(<swift/objc-prologue.h>)
# include <swift/objc-prologue.h>
#endif

#pragma clang diagnostic ignored "-Wauto-import"
#include <Foundation/Foundation.h>
#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

#if !defined(SWIFT_TYPEDEFS)
# define SWIFT_TYPEDEFS 1
# if __has_include(<uchar.h>)
#  include <uchar.h>
# elif !defined(__cplusplus)
typedef uint_least16_t char16_t;
typedef uint_least32_t char32_t;
# endif
typedef float swift_float2  __attribute__((__ext_vector_type__(2)));
typedef float swift_float3  __attribute__((__ext_vector_type__(3)));
typedef float swift_float4  __attribute__((__ext_vector_type__(4)));
typedef double swift_double2  __attribute__((__ext_vector_type__(2)));
typedef double swift_double3  __attribute__((__ext_vector_type__(3)));
typedef double swift_double4  __attribute__((__ext_vector_type__(4)));
typedef int swift_int2  __attribute__((__ext_vector_type__(2)));
typedef int swift_int3  __attribute__((__ext_vector_type__(3)));
typedef int swift_int4  __attribute__((__ext_vector_type__(4)));
typedef unsigned int swift_uint2  __attribute__((__ext_vector_type__(2)));
typedef unsigned int swift_uint3  __attribute__((__ext_vector_type__(3)));
typedef unsigned int swift_uint4  __attribute__((__ext_vector_type__(4)));
#endif

#if !defined(SWIFT_PASTE)
# define SWIFT_PASTE_HELPER(x, y) x##y
# define SWIFT_PASTE(x, y) SWIFT_PASTE_HELPER(x, y)
#endif
#if !defined(SWIFT_METATYPE)
# define SWIFT_METATYPE(X) Class
#endif
#if !defined(SWIFT_CLASS_PROPERTY)
# if __has_feature(objc_class_property)
#  define SWIFT_CLASS_PROPERTY(...) __VA_ARGS__
# else
#  define SWIFT_CLASS_PROPERTY(...)
# endif
#endif

#if __has_attribute(objc_runtime_name)
# define SWIFT_RUNTIME_NAME(X) __attribute__((objc_runtime_name(X)))
#else
# define SWIFT_RUNTIME_NAME(X)
#endif
#if __has_attribute(swift_name)
# define SWIFT_COMPILE_NAME(X) __attribute__((swift_name(X)))
#else
# define SWIFT_COMPILE_NAME(X)
#endif
#if __has_attribute(objc_method_family)
# define SWIFT_METHOD_FAMILY(X) __attribute__((objc_method_family(X)))
#else
# define SWIFT_METHOD_FAMILY(X)
#endif
#if __has_attribute(noescape)
# define SWIFT_NOESCAPE __attribute__((noescape))
#else
# define SWIFT_NOESCAPE
#endif
#if __has_attribute(ns_consumed)
# define SWIFT_RELEASES_ARGUMENT __attribute__((ns_consumed))
#else
# define SWIFT_RELEASES_ARGUMENT
#endif
#if __has_attribute(warn_unused_result)
# define SWIFT_WARN_UNUSED_RESULT __attribute__((warn_unused_result))
#else
# define SWIFT_WARN_UNUSED_RESULT
#endif
#if __has_attribute(noreturn)
# define SWIFT_NORETURN __attribute__((noreturn))
#else
# define SWIFT_NORETURN
#endif
#if !defined(SWIFT_CLASS_EXTRA)
# define SWIFT_CLASS_EXTRA
#endif
#if !defined(SWIFT_PROTOCOL_EXTRA)
# define SWIFT_PROTOCOL_EXTRA
#endif
#if !defined(SWIFT_ENUM_EXTRA)
# define SWIFT_ENUM_EXTRA
#endif
#if !defined(SWIFT_CLASS)
# if __has_attribute(objc_subclassing_restricted)
#  define SWIFT_CLASS(SWIFT_NAME) SWIFT_RUNTIME_NAME(SWIFT_NAME) __attribute__((objc_subclassing_restricted)) SWIFT_CLASS_EXTRA
#  define SWIFT_CLASS_NAMED(SWIFT_NAME) __attribute__((objc_subclassing_restricted)) SWIFT_COMPILE_NAME(SWIFT_NAME) SWIFT_CLASS_EXTRA
# else
#  define SWIFT_CLASS(SWIFT_NAME) SWIFT_RUNTIME_NAME(SWIFT_NAME) SWIFT_CLASS_EXTRA
#  define SWIFT_CLASS_NAMED(SWIFT_NAME) SWIFT_COMPILE_NAME(SWIFT_NAME) SWIFT_CLASS_EXTRA
# endif
#endif
#if !defined(SWIFT_RESILIENT_CLASS)
# if __has_attribute(objc_class_stub)
#  define SWIFT_RESILIENT_CLASS(SWIFT_NAME) SWIFT_CLASS(SWIFT_NAME) __attribute__((objc_class_stub))
#  define SWIFT_RESILIENT_CLASS_NAMED(SWIFT_NAME) __attribute__((objc_class_stub)) SWIFT_CLASS_NAMED(SWIFT_NAME)
# else
#  define SWIFT_RESILIENT_CLASS(SWIFT_NAME) SWIFT_CLASS(SWIFT_NAME)
#  define SWIFT_RESILIENT_CLASS_NAMED(SWIFT_NAME) SWIFT_CLASS_NAMED(SWIFT_NAME)
# endif
#endif

#if !defined(SWIFT_PROTOCOL)
# define SWIFT_PROTOCOL(SWIFT_NAME) SWIFT_RUNTIME_NAME(SWIFT_NAME) SWIFT_PROTOCOL_EXTRA
# define SWIFT_PROTOCOL_NAMED(SWIFT_NAME) SWIFT_COMPILE_NAME(SWIFT_NAME) SWIFT_PROTOCOL_EXTRA
#endif

#if !defined(SWIFT_EXTENSION)
# define SWIFT_EXTENSION(M) SWIFT_PASTE(M##_Swift_, __LINE__)
#endif

#if !defined(OBJC_DESIGNATED_INITIALIZER)
# if __has_attribute(objc_designated_initializer)
#  define OBJC_DESIGNATED_INITIALIZER __attribute__((objc_designated_initializer))
# else
#  define OBJC_DESIGNATED_INITIALIZER
# endif
#endif
#if !defined(SWIFT_ENUM_ATTR)
# if defined(__has_attribute) && __has_attribute(enum_extensibility)
#  define SWIFT_ENUM_ATTR(_extensibility) __attribute__((enum_extensibility(_extensibility)))
# else
#  define SWIFT_ENUM_ATTR(_extensibility)
# endif
#endif
#if !defined(SWIFT_ENUM)
# define SWIFT_ENUM(_type, _name, _extensibility) enum _name : _type _name; enum SWIFT_ENUM_ATTR(_extensibility) SWIFT_ENUM_EXTRA _name : _type
# if __has_feature(generalized_swift_name)
#  define SWIFT_ENUM_NAMED(_type, _name, SWIFT_NAME, _extensibility) enum _name : _type _name SWIFT_COMPILE_NAME(SWIFT_NAME); enum SWIFT_COMPILE_NAME(SWIFT_NAME) SWIFT_ENUM_ATTR(_extensibility) SWIFT_ENUM_EXTRA _name : _type
# else
#  define SWIFT_ENUM_NAMED(_type, _name, SWIFT_NAME, _extensibility) SWIFT_ENUM(_type, _name, _extensibility)
# endif
#endif
#if !defined(SWIFT_UNAVAILABLE)
# define SWIFT_UNAVAILABLE __attribute__((unavailable))
#endif
#if !defined(SWIFT_UNAVAILABLE_MSG)
# define SWIFT_UNAVAILABLE_MSG(msg) __attribute__((unavailable(msg)))
#endif
#if !defined(SWIFT_AVAILABILITY)
# define SWIFT_AVAILABILITY(plat, ...) __attribute__((availability(plat, __VA_ARGS__)))
#endif
#if !defined(SWIFT_WEAK_IMPORT)
# define SWIFT_WEAK_IMPORT __attribute__((weak_import))
#endif
#if !defined(SWIFT_DEPRECATED)
# define SWIFT_DEPRECATED __attribute__((deprecated))
#endif
#if !defined(SWIFT_DEPRECATED_MSG)
# define SWIFT_DEPRECATED_MSG(...) __attribute__((deprecated(__VA_ARGS__)))
#endif
#if __has_feature(attribute_diagnose_if_objc)
# define SWIFT_DEPRECATED_OBJC(Msg) __attribute__((diagnose_if(1, Msg, "warning")))
#else
# define SWIFT_DEPRECATED_OBJC(Msg) SWIFT_DEPRECATED_MSG(Msg)
#endif
#if !defined(IBSegueAction)
# define IBSegueAction
#endif
#if __has_feature(modules)
#if __has_warning("-Watimport-in-framework-header")
#pragma clang diagnostic ignored "-Watimport-in-framework-header"
#endif
@import Foundation;
@import ObjectiveC;
@import UIKit;
#endif

#pragma clang diagnostic ignored "-Wproperty-attribute-mismatch"
#pragma clang diagnostic ignored "-Wduplicate-method-arg"
#if __has_warning("-Wpragma-clang-attribute")
# pragma clang diagnostic ignored "-Wpragma-clang-attribute"
#endif
#pragma clang diagnostic ignored "-Wunknown-pragmas"
#pragma clang diagnostic ignored "-Wnullability"

#if __has_attribute(external_source_symbol)
# pragma push_macro("any")
# undef any
# pragma clang attribute push(__attribute__((external_source_symbol(language="Swift", defined_in="GooidSDK",generated_declaration))), apply_to=any(function,enum,objc_interface,objc_category,objc_protocol))
# pragma pop_macro("any")
#endif

@class NSString;
@class GooidSDKGooidTicket;
@class UIViewController;
@class NSError;
enum GooidSDKLoginProvider : NSInteger;
enum GooidSDKRegisterProvider : NSInteger;
@class UIApplication;
@class NSNumber;
@class NSURL;
@class GIDSignIn;
@class GIDGoogleUser;

/// gooID SDKクラス
SWIFT_CLASS("_TtC8GooidSDK8GooidSDK")
@interface GooidSDK : NSObject
/// 初期処理
- (nonnull instancetype)init SWIFT_UNAVAILABLE;
+ (nonnull instancetype)new SWIFT_UNAVAILABLE_MSG("-init is unavailable");
/// GooidSDKのsingletonインスタンス
SWIFT_CLASS_PROPERTY(@property (nonatomic, class, readonly, strong) GooidSDK * _Nonnull sharedInstance;)
+ (GooidSDK * _Nonnull)sharedInstance SWIFT_WARN_UNUSED_RESULT;
/// GooidSDKのバージョン
@property (nonatomic, readonly, copy) NSString * _Nonnull version;
/// logging mode
/// <ul>
///   <li>
///     NONE
///   </li>
///   <li>
///     INFO
///   </li>
///   <li>
///     DEBUG
///   </li>
///   <li>
///     TRACE
///   </li>
/// </ul>
/// exp. GooidSDK.shareInstance.loggingMode = “DEBUG”
@property (nonatomic, copy) NSString * _Nonnull loggingMode;
/// gooID-SDK内に保存されているgooIDチケットを取得する。
///
/// returns:
/// gooIDチケット
- (GooidSDKGooidTicket * _Nullable)gooidTicket SWIFT_WARN_UNUSED_RESULT;
/// ログインページを表示し、gooIDおよび外部IDでのログインを行う。
/// 発行されたgooIDチケットはgooID-SDK内に保存される。
/// \param viewController ログインページを表示する親ViewController
///
/// \param completion 実行結果を返すクロージャ、成功時はticketにgooIDチケットをセット、失敗時はticket=nil
///
/// \param ticket ログイン成功時にgooIDチケットをセット、失敗時はnil
///
/// \param error エラー情報
///
- (void)login:(UIViewController * _Nonnull)viewController completion:(void (^ _Nonnull)(GooidSDKGooidTicket * _Nullable, NSError * _Nullable))completion;
/// gooIDまたは外部IDを指定し(ログインページを表示せず)、ログインを行う。
/// 発行されたgooIDチケットはgooID-SDK内に保存される。
/// \param viewController 認証時のViewを表示する親ViewController
///
/// \param provider 認証を行うプロバイダ、gooIDまたは外部ID
///
/// \param completion 実行結果を返すクロージャ、成功時はticketにgooIDチケットをセット、失敗時はticket=nil
///
/// \param ticket ログイン成功時にgooIDチケットをセット、失敗時はnil
///
/// \param error エラー情報
///
- (void)login:(UIViewController * _Nonnull)viewController provider:(enum GooidSDKLoginProvider)provider completion:(void (^ _Nonnull)(GooidSDKGooidTicket * _Nullable, NSError * _Nullable))completion;
/// gooID-SDK内に保存されているgooIDチケットの削除(ログアウト)を行う。
- (void)logout;
/// 有効期間を超過したgooIDチケットの更新要求を行う。
/// 更新されたgooIDチケットはgooID-SDK内に保存される。
/// \param completion 実行結果を返すクロージャ、成功時はticketに新しいgooIDチケットをセット、失敗時はticket=nil
///
/// \param ticket 更新成功時に新しいgooIDチケットをセット、失敗時はnil
///
/// \param error エラー情報
///
- (void)refreshGooidTicket:(void (^ _Nonnull)(GooidSDKGooidTicket * _Nullable, NSError * _Nullable))completion;
/// gooIDの新規会員登録要求を行う。
/// 会員登録時に発行されたgooIDチケットはgooID-SDK内に保存される。
/// \param viewController gooID新規登録ページを表示する親ViewController
///
/// \param completion 実行結果を返すクロージャ、成功時はticketにgooIDチケットをセット、失敗時はticket=nil
///
/// \param ticket 新規登録成功時にgooIDチケットをセット、失敗時はnil
///
/// \param error エラー情報
///
- (void)register:(UIViewController * _Nonnull)viewController completion:(void (^ _Nonnull)(GooidSDKGooidTicket * _Nullable, NSError * _Nullable))completion;
/// メールアドレスおよび外部IDでのgooID新規登録を行う。
/// 発行されたgooIDチケットはgooID-SDK内に保存される。
/// \param viewController gooID新規登録ページを表示する親ViewController
///
/// \param provider 認証を行うプロバイダ、メールアドレスまたは外部ID
///
/// \param completion 実行結果を返すクロージャ、成功時はticketにgooIDチケットをセット、失敗時はticket=nil
///
/// \param ticket 新規登録成功時にgooIDチケットをセット、失敗時はnil
///
/// \param error エラー情報
///
- (void)register:(UIViewController * _Nonnull)viewController provider:(enum GooidSDKRegisterProvider)provider completion:(void (^ _Nonnull)(GooidSDKGooidTicket * _Nullable, NSError * _Nullable))completion;
/// gooIDおよびNumber方式対応サービスの一括登録要求を行う。
/// 会員登録時に発行されたgooIDチケットはgooID-SDK内に保存される。
/// \param viewController gooID新規登録ページを表示する親ViewController
///
/// \param completion 実行結果を返すクロージャ、成功時はticketにgooIDチケットをセット、失敗時はticket=nil
///
/// \param ticket 新規登録成功時にgooIDチケットをセット、失敗時はnil
///
/// \param error エラー情報
///
- (void)registerGooidService:(UIViewController * _Nonnull)viewController completion:(void (^ _Nonnull)(GooidSDKGooidTicket * _Nullable, NSError * _Nullable))completion;
/// メールアドレスおよびNumber方式対応サービスの一括登録要求を行う。
/// 会員登録時に発行されたgooIDチケットはgooID-SDK内に保存される。
/// \param viewController gooID新規登録ページを表示する親ViewController
///
/// \param provider 認証を行うプロバイダ、メールアドレスまたは外部ID
///
/// \param completion 実行結果を返すクロージャ、成功時はticketにgooIDチケットをセット、失敗時はticket=nil
///
/// \param ticket 新規登録成功時にgooIDチケットをセット、失敗時はnil
///
/// \param error エラー情報
///
- (void)registerGooidService:(UIViewController * _Nonnull)viewController provider:(enum GooidSDKRegisterProvider)provider completion:(void (^ _Nonnull)(GooidSDKGooidTicket * _Nullable, NSError * _Nullable))completion;
/// Number方式対応サービスの登録要求を行う。
/// \param viewController サービス登録ページを表示する親ViewController
///
/// \param completion 実行結果を返すクロージャ
///
/// \param error 失敗時のエラー情報
///
- (void)registerService:(UIViewController * _Nonnull)viewController completion:(void (^ _Nonnull)(NSError * _Nullable))completion;
/// AppDelegateのapplication(application, launchOptions)内で呼ぶ。
/// FacebookSDKなどの起動時処理を行う。
/// \param application applicationをそのまま指定
///
/// \param didFinishLaunchingWithOptions launchOptionsをそのまま指定
///
///
/// returns:
/// true
- (BOOL)application:(UIApplication * _Nonnull)application didFinishLaunchingWithOptions:(NSDictionary<UIApplicationLaunchOptionsKey, id> * _Nullable)launchOptions SWIFT_WARN_UNUSED_RESULT;
/// AppDelegateのapplicationDidBecomeActive(application)内で呼ぶ。
/// FacebookSDKなどの復帰時処理を行う。
/// \param application applicationをそのまま指定
///
- (void)applicationDidBecomeActive:(UIApplication * _Nonnull)application;
/// AppDelegateのapplication(application, url, sourceApplication, annotation)内で呼ぶ。
/// FacebookSDKなどのカスタムURLスキーム呼び出し時の処理を行う。
/// \param application applicationをそのまま指定
///
/// \param openURL urlをそのまま指定
///
/// \param sourceApplication sourceApplicationをそのまま指定
///
/// \param annotation annotationをそのまま指定
///
///
/// returns:
/// GooidSDK用のURLであればtrue,それ以外はfalseを返す
- (BOOL)application:(UIApplication * _Nonnull)application openURL:(NSURL * _Nonnull)url sourceApplication:(NSString * _Nullable)sourceApplication annotation:(id _Nonnull)annotation SWIFT_WARN_UNUSED_RESULT;
/// AppDelegateのapplication(application, url, options)内で呼ぶ。
/// FacebookSDKなどのカスタムURLスキーム呼び出し時の処理を行う。
/// iOS9.0+
/// \param application applicationをそのまま指定
///
/// \param open urlをそのまま指定
///
/// \param options optionsをそのまま指定
///
///
/// returns:
/// GooidSDK用のURLであればtrue,それ以外はfalseを返す
- (BOOL)application:(UIApplication * _Nonnull)application open:(NSURL * _Nonnull)url options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> * _Nonnull)options SWIFT_WARN_UNUSED_RESULT;
/// AppDelegateのsign(signIn, didSignInFor, withError)内で呼ぶ。
/// Google認証時に利用される。
/// \param signIn signInをそのまま指定
///
/// \param didSignInFor didSignInForをそのまま指定
///
/// \param withError withErrorをそのまま指定
///
- (void)sign:(GIDSignIn * _Null_unspecified)signIn didSignInFor:(GIDGoogleUser * _Null_unspecified)user withError:(NSError * _Null_unspecified)error;
/// AppDelegateのsign(signIn, didDisconnectWith, withError)内で呼ぶ。
/// Google認証時に利用される。
/// \param signIn signInをそのまま指定
///
/// \param didDisconnectWith didDisconnectWithをそのまま指定
///
/// \param withError withErrorをそのまま指定
///
- (void)sign:(GIDSignIn * _Null_unspecified)signIn didDisconnectWith:(GIDGoogleUser * _Null_unspecified)user withError:(NSError * _Null_unspecified)error;
@end


/// gooID SDK エラークラス
SWIFT_CLASS("_TtC8GooidSDK13GooidSDKError")
@interface GooidSDKError : NSObject
/// イニシャライザ
/// \param error NSErrorインスタンス
///
- (nonnull instancetype)initWithError:(NSError * _Nullable)error OBJC_DESIGNATED_INITIALIZER;
/// エラーメッセージ
@property (nonatomic, readonly, copy) NSString * _Nonnull description;
/// キャンセルの場合 trueを返す
@property (nonatomic, readonly) BOOL isCancel;
/// エラーの場合 trueを返す
@property (nonatomic, readonly) BOOL isError;
- (nonnull instancetype)init SWIFT_UNAVAILABLE;
+ (nonnull instancetype)new SWIFT_UNAVAILABLE_MSG("-init is unavailable");
@end

@class NSHTTPCookie;

/// gooIDチケットクラス
SWIFT_CLASS("_TtC8GooidSDK19GooidSDKGooidTicket")
@interface GooidSDKGooidTicket : NSObject
@property (nonatomic, readonly, copy) NSString * _Nonnull userIdForGA;
/// イニシャライザ
- (nonnull instancetype)init SWIFT_UNAVAILABLE;
+ (nonnull instancetype)new SWIFT_UNAVAILABLE_MSG("-init is unavailable");
/// gooIDチケット Cookie値(https)
/// gooIDチケットを構成するCookie群を返す
@property (nonatomic, readonly, copy) NSArray<NSHTTPCookie *> * _Nonnull httpsCookies;
/// gooIDチケット Cookie値(http)
/// gooIDチケットを構成するCookie群のうち、non-secureの値のみを返す
@property (nonatomic, readonly, copy) NSArray<NSHTTPCookie *> * _Nonnull httpCookies;
/// is empty
@property (nonatomic, readonly) BOOL isEmpty;
@end


@interface GooidSDKGooidTicket (SWIFT_EXTENSION(GooidSDK))
@property (nonatomic, readonly, copy) NSString * _Nonnull description;
@end

/// 外部ID連携ログイン プロバイダー
typedef SWIFT_ENUM(NSInteger, GooidSDKLoginProvider, closed) {
  GooidSDKLoginProviderGooid = 0,
  GooidSDKLoginProviderOcn = 1,
  GooidSDKLoginProviderDocomo = 2,
  GooidSDKLoginProviderGoogle = 3,
  GooidSDKLoginProviderYahoo = 4,
  GooidSDKLoginProviderTwitter = 5,
  GooidSDKLoginProviderFacebook = 6,
  GooidSDKLoginProviderApple = 7,
};

/// 外部ID連携登録 プロバイダー
typedef SWIFT_ENUM(NSInteger, GooidSDKRegisterProvider, closed) {
  GooidSDKRegisterProviderMailaddress = 0,
  GooidSDKRegisterProviderOcn = 1,
  GooidSDKRegisterProviderDocomo = 2,
  GooidSDKRegisterProviderGoogle = 3,
  GooidSDKRegisterProviderYahoo = 4,
  GooidSDKRegisterProviderTwitter = 5,
  GooidSDKRegisterProviderFacebook = 6,
  GooidSDKRegisterProviderApple = 7,
};


#if __has_attribute(external_source_symbol)
# pragma clang attribute pop
#endif
#pragma clang diagnostic pop
#endif
#else
//Start of iphoneos
// Generated by Apple Swift version 5.5 (swiftlang-1300.0.29.102 clang-1300.0.28.1)
#ifndef GOOIDSDK_SWIFT_H
#define GOOIDSDK_SWIFT_H
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wgcc-compat"

#if !defined(__has_include)
# define __has_include(x) 0
#endif
#if !defined(__has_attribute)
# define __has_attribute(x) 0
#endif
#if !defined(__has_feature)
# define __has_feature(x) 0
#endif
#if !defined(__has_warning)
# define __has_warning(x) 0
#endif

#if __has_include(<swift/objc-prologue.h>)
# include <swift/objc-prologue.h>
#endif

#pragma clang diagnostic ignored "-Wauto-import"
#include <Foundation/Foundation.h>
#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

#if !defined(SWIFT_TYPEDEFS)
# define SWIFT_TYPEDEFS 1
# if __has_include(<uchar.h>)
#  include <uchar.h>
# elif !defined(__cplusplus)
typedef uint_least16_t char16_t;
typedef uint_least32_t char32_t;
# endif
typedef float swift_float2  __attribute__((__ext_vector_type__(2)));
typedef float swift_float3  __attribute__((__ext_vector_type__(3)));
typedef float swift_float4  __attribute__((__ext_vector_type__(4)));
typedef double swift_double2  __attribute__((__ext_vector_type__(2)));
typedef double swift_double3  __attribute__((__ext_vector_type__(3)));
typedef double swift_double4  __attribute__((__ext_vector_type__(4)));
typedef int swift_int2  __attribute__((__ext_vector_type__(2)));
typedef int swift_int3  __attribute__((__ext_vector_type__(3)));
typedef int swift_int4  __attribute__((__ext_vector_type__(4)));
typedef unsigned int swift_uint2  __attribute__((__ext_vector_type__(2)));
typedef unsigned int swift_uint3  __attribute__((__ext_vector_type__(3)));
typedef unsigned int swift_uint4  __attribute__((__ext_vector_type__(4)));
#endif

#if !defined(SWIFT_PASTE)
# define SWIFT_PASTE_HELPER(x, y) x##y
# define SWIFT_PASTE(x, y) SWIFT_PASTE_HELPER(x, y)
#endif
#if !defined(SWIFT_METATYPE)
# define SWIFT_METATYPE(X) Class
#endif
#if !defined(SWIFT_CLASS_PROPERTY)
# if __has_feature(objc_class_property)
#  define SWIFT_CLASS_PROPERTY(...) __VA_ARGS__
# else
#  define SWIFT_CLASS_PROPERTY(...)
# endif
#endif

#if __has_attribute(objc_runtime_name)
# define SWIFT_RUNTIME_NAME(X) __attribute__((objc_runtime_name(X)))
#else
# define SWIFT_RUNTIME_NAME(X)
#endif
#if __has_attribute(swift_name)
# define SWIFT_COMPILE_NAME(X) __attribute__((swift_name(X)))
#else
# define SWIFT_COMPILE_NAME(X)
#endif
#if __has_attribute(objc_method_family)
# define SWIFT_METHOD_FAMILY(X) __attribute__((objc_method_family(X)))
#else
# define SWIFT_METHOD_FAMILY(X)
#endif
#if __has_attribute(noescape)
# define SWIFT_NOESCAPE __attribute__((noescape))
#else
# define SWIFT_NOESCAPE
#endif
#if __has_attribute(ns_consumed)
# define SWIFT_RELEASES_ARGUMENT __attribute__((ns_consumed))
#else
# define SWIFT_RELEASES_ARGUMENT
#endif
#if __has_attribute(warn_unused_result)
# define SWIFT_WARN_UNUSED_RESULT __attribute__((warn_unused_result))
#else
# define SWIFT_WARN_UNUSED_RESULT
#endif
#if __has_attribute(noreturn)
# define SWIFT_NORETURN __attribute__((noreturn))
#else
# define SWIFT_NORETURN
#endif
#if !defined(SWIFT_CLASS_EXTRA)
# define SWIFT_CLASS_EXTRA
#endif
#if !defined(SWIFT_PROTOCOL_EXTRA)
# define SWIFT_PROTOCOL_EXTRA
#endif
#if !defined(SWIFT_ENUM_EXTRA)
# define SWIFT_ENUM_EXTRA
#endif
#if !defined(SWIFT_CLASS)
# if __has_attribute(objc_subclassing_restricted)
#  define SWIFT_CLASS(SWIFT_NAME) SWIFT_RUNTIME_NAME(SWIFT_NAME) __attribute__((objc_subclassing_restricted)) SWIFT_CLASS_EXTRA
#  define SWIFT_CLASS_NAMED(SWIFT_NAME) __attribute__((objc_subclassing_restricted)) SWIFT_COMPILE_NAME(SWIFT_NAME) SWIFT_CLASS_EXTRA
# else
#  define SWIFT_CLASS(SWIFT_NAME) SWIFT_RUNTIME_NAME(SWIFT_NAME) SWIFT_CLASS_EXTRA
#  define SWIFT_CLASS_NAMED(SWIFT_NAME) SWIFT_COMPILE_NAME(SWIFT_NAME) SWIFT_CLASS_EXTRA
# endif
#endif
#if !defined(SWIFT_RESILIENT_CLASS)
# if __has_attribute(objc_class_stub)
#  define SWIFT_RESILIENT_CLASS(SWIFT_NAME) SWIFT_CLASS(SWIFT_NAME) __attribute__((objc_class_stub))
#  define SWIFT_RESILIENT_CLASS_NAMED(SWIFT_NAME) __attribute__((objc_class_stub)) SWIFT_CLASS_NAMED(SWIFT_NAME)
# else
#  define SWIFT_RESILIENT_CLASS(SWIFT_NAME) SWIFT_CLASS(SWIFT_NAME)
#  define SWIFT_RESILIENT_CLASS_NAMED(SWIFT_NAME) SWIFT_CLASS_NAMED(SWIFT_NAME)
# endif
#endif

#if !defined(SWIFT_PROTOCOL)
# define SWIFT_PROTOCOL(SWIFT_NAME) SWIFT_RUNTIME_NAME(SWIFT_NAME) SWIFT_PROTOCOL_EXTRA
# define SWIFT_PROTOCOL_NAMED(SWIFT_NAME) SWIFT_COMPILE_NAME(SWIFT_NAME) SWIFT_PROTOCOL_EXTRA
#endif

#if !defined(SWIFT_EXTENSION)
# define SWIFT_EXTENSION(M) SWIFT_PASTE(M##_Swift_, __LINE__)
#endif

#if !defined(OBJC_DESIGNATED_INITIALIZER)
# if __has_attribute(objc_designated_initializer)
#  define OBJC_DESIGNATED_INITIALIZER __attribute__((objc_designated_initializer))
# else
#  define OBJC_DESIGNATED_INITIALIZER
# endif
#endif
#if !defined(SWIFT_ENUM_ATTR)
# if defined(__has_attribute) && __has_attribute(enum_extensibility)
#  define SWIFT_ENUM_ATTR(_extensibility) __attribute__((enum_extensibility(_extensibility)))
# else
#  define SWIFT_ENUM_ATTR(_extensibility)
# endif
#endif
#if !defined(SWIFT_ENUM)
# define SWIFT_ENUM(_type, _name, _extensibility) enum _name : _type _name; enum SWIFT_ENUM_ATTR(_extensibility) SWIFT_ENUM_EXTRA _name : _type
# if __has_feature(generalized_swift_name)
#  define SWIFT_ENUM_NAMED(_type, _name, SWIFT_NAME, _extensibility) enum _name : _type _name SWIFT_COMPILE_NAME(SWIFT_NAME); enum SWIFT_COMPILE_NAME(SWIFT_NAME) SWIFT_ENUM_ATTR(_extensibility) SWIFT_ENUM_EXTRA _name : _type
# else
#  define SWIFT_ENUM_NAMED(_type, _name, SWIFT_NAME, _extensibility) SWIFT_ENUM(_type, _name, _extensibility)
# endif
#endif
#if !defined(SWIFT_UNAVAILABLE)
# define SWIFT_UNAVAILABLE __attribute__((unavailable))
#endif
#if !defined(SWIFT_UNAVAILABLE_MSG)
# define SWIFT_UNAVAILABLE_MSG(msg) __attribute__((unavailable(msg)))
#endif
#if !defined(SWIFT_AVAILABILITY)
# define SWIFT_AVAILABILITY(plat, ...) __attribute__((availability(plat, __VA_ARGS__)))
#endif
#if !defined(SWIFT_WEAK_IMPORT)
# define SWIFT_WEAK_IMPORT __attribute__((weak_import))
#endif
#if !defined(SWIFT_DEPRECATED)
# define SWIFT_DEPRECATED __attribute__((deprecated))
#endif
#if !defined(SWIFT_DEPRECATED_MSG)
# define SWIFT_DEPRECATED_MSG(...) __attribute__((deprecated(__VA_ARGS__)))
#endif
#if __has_feature(attribute_diagnose_if_objc)
# define SWIFT_DEPRECATED_OBJC(Msg) __attribute__((diagnose_if(1, Msg, "warning")))
#else
# define SWIFT_DEPRECATED_OBJC(Msg) SWIFT_DEPRECATED_MSG(Msg)
#endif
#if !defined(IBSegueAction)
# define IBSegueAction
#endif
#if __has_feature(modules)
#if __has_warning("-Watimport-in-framework-header")
#pragma clang diagnostic ignored "-Watimport-in-framework-header"
#endif
@import Foundation;
@import ObjectiveC;
@import UIKit;
#endif

#pragma clang diagnostic ignored "-Wproperty-attribute-mismatch"
#pragma clang diagnostic ignored "-Wduplicate-method-arg"
#if __has_warning("-Wpragma-clang-attribute")
# pragma clang diagnostic ignored "-Wpragma-clang-attribute"
#endif
#pragma clang diagnostic ignored "-Wunknown-pragmas"
#pragma clang diagnostic ignored "-Wnullability"

#if __has_attribute(external_source_symbol)
# pragma push_macro("any")
# undef any
# pragma clang attribute push(__attribute__((external_source_symbol(language="Swift", defined_in="GooidSDK",generated_declaration))), apply_to=any(function,enum,objc_interface,objc_category,objc_protocol))
# pragma pop_macro("any")
#endif

@class NSString;
@class GooidSDKGooidTicket;
@class UIViewController;
@class NSError;
enum GooidSDKLoginProvider : NSInteger;
enum GooidSDKRegisterProvider : NSInteger;
@class UIApplication;
@class NSNumber;
@class NSURL;
@class GIDSignIn;
@class GIDGoogleUser;

/// gooID SDKクラス
SWIFT_CLASS("_TtC8GooidSDK8GooidSDK")
@interface GooidSDK : NSObject
/// 初期処理
- (nonnull instancetype)init SWIFT_UNAVAILABLE;
+ (nonnull instancetype)new SWIFT_UNAVAILABLE_MSG("-init is unavailable");
/// GooidSDKのsingletonインスタンス
SWIFT_CLASS_PROPERTY(@property (nonatomic, class, readonly, strong) GooidSDK * _Nonnull sharedInstance;)
+ (GooidSDK * _Nonnull)sharedInstance SWIFT_WARN_UNUSED_RESULT;
/// GooidSDKのバージョン
@property (nonatomic, readonly, copy) NSString * _Nonnull version;
/// logging mode
/// <ul>
///   <li>
///     NONE
///   </li>
///   <li>
///     INFO
///   </li>
///   <li>
///     DEBUG
///   </li>
///   <li>
///     TRACE
///   </li>
/// </ul>
/// exp. GooidSDK.shareInstance.loggingMode = “DEBUG”
@property (nonatomic, copy) NSString * _Nonnull loggingMode;
/// gooID-SDK内に保存されているgooIDチケットを取得する。
///
/// returns:
/// gooIDチケット
- (GooidSDKGooidTicket * _Nullable)gooidTicket SWIFT_WARN_UNUSED_RESULT;
/// ログインページを表示し、gooIDおよび外部IDでのログインを行う。
/// 発行されたgooIDチケットはgooID-SDK内に保存される。
/// \param viewController ログインページを表示する親ViewController
///
/// \param completion 実行結果を返すクロージャ、成功時はticketにgooIDチケットをセット、失敗時はticket=nil
///
/// \param ticket ログイン成功時にgooIDチケットをセット、失敗時はnil
///
/// \param error エラー情報
///
- (void)login:(UIViewController * _Nonnull)viewController completion:(void (^ _Nonnull)(GooidSDKGooidTicket * _Nullable, NSError * _Nullable))completion;
/// gooIDまたは外部IDを指定し(ログインページを表示せず)、ログインを行う。
/// 発行されたgooIDチケットはgooID-SDK内に保存される。
/// \param viewController 認証時のViewを表示する親ViewController
///
/// \param provider 認証を行うプロバイダ、gooIDまたは外部ID
///
/// \param completion 実行結果を返すクロージャ、成功時はticketにgooIDチケットをセット、失敗時はticket=nil
///
/// \param ticket ログイン成功時にgooIDチケットをセット、失敗時はnil
///
/// \param error エラー情報
///
- (void)login:(UIViewController * _Nonnull)viewController provider:(enum GooidSDKLoginProvider)provider completion:(void (^ _Nonnull)(GooidSDKGooidTicket * _Nullable, NSError * _Nullable))completion;
/// gooID-SDK内に保存されているgooIDチケットの削除(ログアウト)を行う。
- (void)logout;
/// 有効期間を超過したgooIDチケットの更新要求を行う。
/// 更新されたgooIDチケットはgooID-SDK内に保存される。
/// \param completion 実行結果を返すクロージャ、成功時はticketに新しいgooIDチケットをセット、失敗時はticket=nil
///
/// \param ticket 更新成功時に新しいgooIDチケットをセット、失敗時はnil
///
/// \param error エラー情報
///
- (void)refreshGooidTicket:(void (^ _Nonnull)(GooidSDKGooidTicket * _Nullable, NSError * _Nullable))completion;
/// gooIDの新規会員登録要求を行う。
/// 会員登録時に発行されたgooIDチケットはgooID-SDK内に保存される。
/// \param viewController gooID新規登録ページを表示する親ViewController
///
/// \param completion 実行結果を返すクロージャ、成功時はticketにgooIDチケットをセット、失敗時はticket=nil
///
/// \param ticket 新規登録成功時にgooIDチケットをセット、失敗時はnil
///
/// \param error エラー情報
///
- (void)register:(UIViewController * _Nonnull)viewController completion:(void (^ _Nonnull)(GooidSDKGooidTicket * _Nullable, NSError * _Nullable))completion;
/// メールアドレスおよび外部IDでのgooID新規登録を行う。
/// 発行されたgooIDチケットはgooID-SDK内に保存される。
/// \param viewController gooID新規登録ページを表示する親ViewController
///
/// \param provider 認証を行うプロバイダ、メールアドレスまたは外部ID
///
/// \param completion 実行結果を返すクロージャ、成功時はticketにgooIDチケットをセット、失敗時はticket=nil
///
/// \param ticket 新規登録成功時にgooIDチケットをセット、失敗時はnil
///
/// \param error エラー情報
///
- (void)register:(UIViewController * _Nonnull)viewController provider:(enum GooidSDKRegisterProvider)provider completion:(void (^ _Nonnull)(GooidSDKGooidTicket * _Nullable, NSError * _Nullable))completion;
/// gooIDおよびNumber方式対応サービスの一括登録要求を行う。
/// 会員登録時に発行されたgooIDチケットはgooID-SDK内に保存される。
/// \param viewController gooID新規登録ページを表示する親ViewController
///
/// \param completion 実行結果を返すクロージャ、成功時はticketにgooIDチケットをセット、失敗時はticket=nil
///
/// \param ticket 新規登録成功時にgooIDチケットをセット、失敗時はnil
///
/// \param error エラー情報
///
- (void)registerGooidService:(UIViewController * _Nonnull)viewController completion:(void (^ _Nonnull)(GooidSDKGooidTicket * _Nullable, NSError * _Nullable))completion;
/// メールアドレスおよびNumber方式対応サービスの一括登録要求を行う。
/// 会員登録時に発行されたgooIDチケットはgooID-SDK内に保存される。
/// \param viewController gooID新規登録ページを表示する親ViewController
///
/// \param provider 認証を行うプロバイダ、メールアドレスまたは外部ID
///
/// \param completion 実行結果を返すクロージャ、成功時はticketにgooIDチケットをセット、失敗時はticket=nil
///
/// \param ticket 新規登録成功時にgooIDチケットをセット、失敗時はnil
///
/// \param error エラー情報
///
- (void)registerGooidService:(UIViewController * _Nonnull)viewController provider:(enum GooidSDKRegisterProvider)provider completion:(void (^ _Nonnull)(GooidSDKGooidTicket * _Nullable, NSError * _Nullable))completion;
/// Number方式対応サービスの登録要求を行う。
/// \param viewController サービス登録ページを表示する親ViewController
///
/// \param completion 実行結果を返すクロージャ
///
/// \param error 失敗時のエラー情報
///
- (void)registerService:(UIViewController * _Nonnull)viewController completion:(void (^ _Nonnull)(NSError * _Nullable))completion;
/// AppDelegateのapplication(application, launchOptions)内で呼ぶ。
/// FacebookSDKなどの起動時処理を行う。
/// \param application applicationをそのまま指定
///
/// \param didFinishLaunchingWithOptions launchOptionsをそのまま指定
///
///
/// returns:
/// true
- (BOOL)application:(UIApplication * _Nonnull)application didFinishLaunchingWithOptions:(NSDictionary<UIApplicationLaunchOptionsKey, id> * _Nullable)launchOptions SWIFT_WARN_UNUSED_RESULT;
/// AppDelegateのapplicationDidBecomeActive(application)内で呼ぶ。
/// FacebookSDKなどの復帰時処理を行う。
/// \param application applicationをそのまま指定
///
- (void)applicationDidBecomeActive:(UIApplication * _Nonnull)application;
/// AppDelegateのapplication(application, url, sourceApplication, annotation)内で呼ぶ。
/// FacebookSDKなどのカスタムURLスキーム呼び出し時の処理を行う。
/// \param application applicationをそのまま指定
///
/// \param openURL urlをそのまま指定
///
/// \param sourceApplication sourceApplicationをそのまま指定
///
/// \param annotation annotationをそのまま指定
///
///
/// returns:
/// GooidSDK用のURLであればtrue,それ以外はfalseを返す
- (BOOL)application:(UIApplication * _Nonnull)application openURL:(NSURL * _Nonnull)url sourceApplication:(NSString * _Nullable)sourceApplication annotation:(id _Nonnull)annotation SWIFT_WARN_UNUSED_RESULT;
/// AppDelegateのapplication(application, url, options)内で呼ぶ。
/// FacebookSDKなどのカスタムURLスキーム呼び出し時の処理を行う。
/// iOS9.0+
/// \param application applicationをそのまま指定
///
/// \param open urlをそのまま指定
///
/// \param options optionsをそのまま指定
///
///
/// returns:
/// GooidSDK用のURLであればtrue,それ以外はfalseを返す
- (BOOL)application:(UIApplication * _Nonnull)application open:(NSURL * _Nonnull)url options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> * _Nonnull)options SWIFT_WARN_UNUSED_RESULT;
/// AppDelegateのsign(signIn, didSignInFor, withError)内で呼ぶ。
/// Google認証時に利用される。
/// \param signIn signInをそのまま指定
///
/// \param didSignInFor didSignInForをそのまま指定
///
/// \param withError withErrorをそのまま指定
///
- (void)sign:(GIDSignIn * _Null_unspecified)signIn didSignInFor:(GIDGoogleUser * _Null_unspecified)user withError:(NSError * _Null_unspecified)error;
/// AppDelegateのsign(signIn, didDisconnectWith, withError)内で呼ぶ。
/// Google認証時に利用される。
/// \param signIn signInをそのまま指定
///
/// \param didDisconnectWith didDisconnectWithをそのまま指定
///
/// \param withError withErrorをそのまま指定
///
- (void)sign:(GIDSignIn * _Null_unspecified)signIn didDisconnectWith:(GIDGoogleUser * _Null_unspecified)user withError:(NSError * _Null_unspecified)error;
@end


/// gooID SDK エラークラス
SWIFT_CLASS("_TtC8GooidSDK13GooidSDKError")
@interface GooidSDKError : NSObject
/// イニシャライザ
/// \param error NSErrorインスタンス
///
- (nonnull instancetype)initWithError:(NSError * _Nullable)error OBJC_DESIGNATED_INITIALIZER;
/// エラーメッセージ
@property (nonatomic, readonly, copy) NSString * _Nonnull description;
/// キャンセルの場合 trueを返す
@property (nonatomic, readonly) BOOL isCancel;
/// エラーの場合 trueを返す
@property (nonatomic, readonly) BOOL isError;
- (nonnull instancetype)init SWIFT_UNAVAILABLE;
+ (nonnull instancetype)new SWIFT_UNAVAILABLE_MSG("-init is unavailable");
@end

@class NSHTTPCookie;

/// gooIDチケットクラス
SWIFT_CLASS("_TtC8GooidSDK19GooidSDKGooidTicket")
@interface GooidSDKGooidTicket : NSObject
@property (nonatomic, readonly, copy) NSString * _Nonnull userIdForGA;
/// イニシャライザ
- (nonnull instancetype)init SWIFT_UNAVAILABLE;
+ (nonnull instancetype)new SWIFT_UNAVAILABLE_MSG("-init is unavailable");
/// gooIDチケット Cookie値(https)
/// gooIDチケットを構成するCookie群を返す
@property (nonatomic, readonly, copy) NSArray<NSHTTPCookie *> * _Nonnull httpsCookies;
/// gooIDチケット Cookie値(http)
/// gooIDチケットを構成するCookie群のうち、non-secureの値のみを返す
@property (nonatomic, readonly, copy) NSArray<NSHTTPCookie *> * _Nonnull httpCookies;
/// is empty
@property (nonatomic, readonly) BOOL isEmpty;
@end


@interface GooidSDKGooidTicket (SWIFT_EXTENSION(GooidSDK))
@property (nonatomic, readonly, copy) NSString * _Nonnull description;
@end

/// 外部ID連携ログイン プロバイダー
typedef SWIFT_ENUM(NSInteger, GooidSDKLoginProvider, closed) {
  GooidSDKLoginProviderGooid = 0,
  GooidSDKLoginProviderOcn = 1,
  GooidSDKLoginProviderDocomo = 2,
  GooidSDKLoginProviderGoogle = 3,
  GooidSDKLoginProviderYahoo = 4,
  GooidSDKLoginProviderTwitter = 5,
  GooidSDKLoginProviderFacebook = 6,
  GooidSDKLoginProviderApple = 7,
};

/// 外部ID連携登録 プロバイダー
typedef SWIFT_ENUM(NSInteger, GooidSDKRegisterProvider, closed) {
  GooidSDKRegisterProviderMailaddress = 0,
  GooidSDKRegisterProviderOcn = 1,
  GooidSDKRegisterProviderDocomo = 2,
  GooidSDKRegisterProviderGoogle = 3,
  GooidSDKRegisterProviderYahoo = 4,
  GooidSDKRegisterProviderTwitter = 5,
  GooidSDKRegisterProviderFacebook = 6,
  GooidSDKRegisterProviderApple = 7,
};


#if __has_attribute(external_source_symbol)
# pragma clang attribute pop
#endif
#pragma clang diagnostic pop
#endif
#endif
