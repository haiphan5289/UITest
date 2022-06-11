//
//  RemoteConfigFirestoreGateway.swift
//  GooDic
//
//  Created by ttvu on 6/11/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation
import RxSwift
import FirebaseFirestore
import RxFirebaseFirestore
import FirebaseAuth

// fetching data from FirebaseFirestore
public struct RemoteConfigFirestoreGateway: RemoteConfigGatewayProtocol {

    struct Constant {
        static let configuration = "configuration"
        static let terms = "terms_auth"
        static let revisionDate = "revision_date"
        static let notiWebview = "billing_appeal"
        static let notiDictionary = "billing_appeal2"
        static let notiHome = "home"
        static let notification = "notification"
        static let uiText = "ui_text"
        static let billing = "billing"
        static let forceUpdate = "force_update"
    }
    
    let db = Firestore.firestore()
    
    public func agreementDate() -> Observable<Date?> {
        return signInAnonymously()
            .flatMapLatest({ (user) -> Observable<Date?> in
                return self.readAgreementDate()
            })
    }
    
    public func notifyWebview() -> Observable<NotiWebModel?> {
        return signInAnonymously()
            .flatMapLatest({ (user) -> Observable<NotiWebModel?> in
                return self.readNotiWebview()
            })
        
    }
    
    public func notifyDictionary() -> Observable<NotiWebModel?> {
        return signInAnonymously()
            .flatMapLatest({ (user) -> Observable<NotiWebModel?> in
                return self.readNotiDictionary()
            })
        
    }

    public func titleForBanner() -> Observable<NotificationBannerHome?> {
        return signInAnonymously()
            .flatMapLatest({ (user) -> Observable<NotificationBannerHome?> in
                return self.getTitleForBanner()

            })
    }
    
    public func getUIBillingTextValue() -> Observable<FileStoreBillingText?> {
        return signInAnonymously()
            .flatMapLatest({ (user) -> Observable<FileStoreBillingText?> in
                return self.getUITextValue()
            })
    }
    
    public func getDataforceUpdate() -> Observable<FileStoreForceUpdate?> {
        return signInAnonymously()
            .flatMapLatest({ (user) -> Observable<FileStoreForceUpdate?> in
                return self.getForceUpdate()
            })
    }
    
    func signInAnonymously() -> Observable<User> {
        return Observable.create { observer in
            // If there is already an anonymous user signed in, that user will be returned instead.
            // The anonymous users never expire.
            Auth.auth().signInAnonymously { (authResult, error) in
                if let error = error {
                    observer.onError(error)
                    return
                }
                
                guard let user = authResult?.user else {
                    observer.onError(NSError(domain: AuthErrorDomain,
                                             code: AuthErrorCode.nullUser.rawValue,
                                             userInfo: nil))
                    return
                }
                
                observer.onNext(user)
                observer.onCompleted()
            }
            
            return Disposables.create()
        }
    }
    
    func readAgreementDate() -> Observable<Date?> {
        return db.collection(Constant.configuration).document(Constant.terms).rx
            .getDocument(source: .server)
            .map ({ (document) -> Date? in
                if let timestamp = document.get(Constant.revisionDate) as? Timestamp {
                    return timestamp.dateValue()
                } else {
                    return nil
                }
            })
    }
    
    func readNotiDictionary() -> Observable<NotiWebModel?> {
        return  db.collection(Constant.configuration).document(Constant.notiDictionary).rx
            .getDocument(source: .server)
            .map ({ (document) -> NotiWebModel? in
                return document.convertData?.toCodableObject(type: NotiWebModel.self)
            })
    }
    
    func readNotiWebview() -> Observable<NotiWebModel?> {
        return  db.collection(Constant.configuration).document(Constant.notiWebview).rx
            .getDocument(source: .server)
            .map ({ (document) -> NotiWebModel? in
                return document.convertData?.toCodableObject(type: NotiWebModel.self)
            })
    }
    
    func getTitleForBanner() -> Observable<NotificationBannerHome?> {
        return db.collection(Constant.notification).document(Constant.notiHome).rx
            .getDocument(source: .server)
            .map ({ (document) -> NotificationBannerHome? in
                do {
                    let noti = try document.decode(as: NotificationBannerHome.self)
                    return noti
                } catch {
                    return nil
                }
            })
    }
    
    func getUITextValue() -> Observable<FileStoreBillingText?> {
        return db.collection(Constant.uiText)
            .document(Constant.billing).rx
            .getDocument(source: .server)
            .map ({ (document) -> FileStoreBillingText? in
                return document.convertData?.toCodableObject(type: FileStoreBillingText.self)
            })
    }
    
    func getForceUpdate() -> Observable<FileStoreForceUpdate?> {
        return db.collection(Constant.configuration)
            .document(Constant.forceUpdate).rx
            .getDocument(source: .server)
            .map ({ (document) -> FileStoreForceUpdate? in
                do {
                    let forceUpdate = try document.decode(as: FileStoreForceUpdate.self)
                    return forceUpdate
                } catch {
                    return nil
                }
            }).catchError { (error) -> Observable<FileStoreForceUpdate?> in
                return Observable.just(nil)
            }
    }
}

enum DocumentSnapshotExtensionError:Error {
    case decodingError
}

extension DocumentSnapshot {
    func decode<T: Decodable>(as objectType: T.Type, includingId: Bool = true) throws -> T {
            print("decoding snapshot for ", T.self)
            do {
                guard var documentJson = self.data() else {throw DocumentSnapshotExtensionError.decodingError}
                if includingId {
                    print("setting ID on document to", self.documentID)
                    documentJson["id"] = self.documentID
                }
                
                //transform any values in the data object as needed
                documentJson.forEach { (key: String, value: Any) in
                    switch value{
                    case let ref as DocumentReference:
                        print("document ref path", ref.path)
                        documentJson.removeValue(forKey: key)
                        break
                    case let ts as Timestamp: //convert timestamp to date value
                        print("converting timestamp to date for field \(key)")
                        let date = ts.dateValue()
                        
                        let jsonValue = Int((date.timeIntervalSince1970 * 1000).rounded())
                        documentJson[key] = jsonValue
                        
                        print("set \(key) to \(jsonValue)")
                        break
                    default:
                        break
                    }
                }
                
                print("getting doucument data")
                let documentData = try JSONSerialization.data(withJSONObject: documentJson, options: [])
                print("Got document data, decoding into object", documentData)
                
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .millisecondsSince1970
                
                let decodedObject = try decoder.decode(objectType, from: documentData)
                print("finished decoding DocumentSnapshot", decodedObject)
                return decodedObject
            } catch {
                print("failed to decode", error)
                throw error
            }
            
        }
}
