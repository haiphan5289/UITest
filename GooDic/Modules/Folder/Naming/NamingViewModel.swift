//
//  NamingViewModel.swift
//  GooDic
//
//  Created by ttvu on 10/6/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

enum UpdateFolderResult {
    case cancel
    case updatedLocalFolder
    case updatedCloudFolder
}

struct NamingViewModel {
    let title: String
    let message: String
    let confirmButtonName: String
    let folder: Folder?
    let createCloudFolderAsDefault: Bool
    let navigator: NamingNavigateProtocol
    let useCase: NamingUseCaseProtocol
    let valueIndex: Double?
    
    let delegate: PublishSubject<UpdateFolderResult>
}

extension NamingViewModel: ViewModelProtocol {
    struct UpdateFolderData {
        let name: String
        let folder: Folder?
        let isCloud: Bool
    }
    
    struct Input {
        let loadTrigger: Driver<Void>
        let nameTrigger: Driver<String>
        let isCloudTrigger: Driver<Void>
        let cancelTrigger: Driver<Void>
        let okTrigger: Driver<Void>
        let userInfo: Driver<UserInfo?>
    }
    
    struct Output {
        let title: Driver<String>
        let message: Driver<String>
        let confirmButtonName: Driver<String>
        let warningMessage: Driver<String>
        let startWithName: Driver<String>
        let dismiss: Driver<Void>
        let isCloud: Driver<Bool>
        let showCloudCheckbox: Driver<Bool>
        let keyboardHeight: Driver<PresentAnim>
        let loading: Driver<Bool>
    }
    
    func transform(_ input: Input) -> Output {
        let folderStream = Driver.just(folder)
        
        // to show the folder name at starting
        let startWithName = input.loadTrigger
            .withLatestFrom(folderStream)
            .map({ $0?.name ?? "" })
        
        // to show the title
        let titleStream = input.loadTrigger
            .withLatestFrom(Driver.just(title))
            
        // to show the message (description)
        let messageStream = input.loadTrigger
            .withLatestFrom(Driver.just(message))
        
        // to show the title of Ok Button
        let confirmButtonNameStream = input.loadTrigger
            .withLatestFrom(Driver.just(confirmButtonName))
        
        // cloud CheckBox value
        let createOnCloud = BehaviorSubject(value: self.folder?.id.cloudID != nil ? true : createCloudFolderAsDefault)
        let isCloud = Driver
            .merge(
                input.loadTrigger
                    .withLatestFrom(createOnCloud.asDriverOnErrorJustComplete()),
                input.isCloudTrigger
                    .withLatestFrom(createOnCloud.asDriverOnErrorJustComplete())
                    .map({ !$0 }))
            .do(onNext: { createOnCloud.onNext($0) })
        
        //  allow to create a cloud folder only if users have logged in and have registered at least one device
        let showCloudCheckbox = input.loadTrigger
            .withLatestFrom(Driver.combineLatest(folderStream, input.userInfo))
            .flatMap({ (folder, userInfo) -> Driver<Bool> in
                if folder != nil {
                    return Driver.just(false)
                }
                
                if let userInfo = userInfo, userInfo.deviceStatus == .registered { // login
                    return Driver.just(true)
                }

                return Driver.just(false)
            })
        
        let warningMessage = BehaviorSubject<String>(value: "")
        let activityIndicator = ActivityIndicator()
        
        // Action when clicking on the Ok button
        let actionData = Driver
            .combineLatest(
                input.nameTrigger,
                folderStream,
                createOnCloud.asDriverOnErrorJustComplete(),
                resultSelector: { UpdateFolderData(name: $0, folder: $1, isCloud: $2)})
        
        let dataTrigger = input.okTrigger
            .withLatestFrom(actionData)
        
        let action = updateFolderFlow(dataTrigger: dataTrigger,
                                      warningMessage: warningMessage,
                                      activityIndicator: activityIndicator)
        
        let dismissTrigger = Driver.merge(input.cancelTrigger, action)
            .do(onNext: {
                self.delegate.onNext(.cancel)
                self.navigator.dismiss()
            })
        
        // keyboard height
        let keyboardHeight = keyboardHandle()
            .takeUntil(dismissTrigger.asObservable())
            .asDriverOnErrorJustComplete()
        
        return Output(
            title: titleStream,
            message: messageStream,
            confirmButtonName: confirmButtonNameStream,
            warningMessage: warningMessage.asDriverOnErrorJustComplete(),
            startWithName: startWithName,
            dismiss: dismissTrigger,
            isCloud: isCloud,
            showCloudCheckbox: showCloudCheckbox,
            keyboardHeight: keyboardHeight,
            loading: activityIndicator.asDriver()
        )
    }
    
    func updateFolderFlow(dataTrigger: Driver<UpdateFolderData>,
                          warningMessage: BehaviorSubject<String>,
                          activityIndicator: ActivityIndicator) -> Driver<Void> {
        let retry = BehaviorRelay<Int>(value: 0)
        let error = ErrorTracker()
        let errorHandler = error
            .withLatestFrom(dataTrigger, resultSelector: { (error: $0, data: $1) })
            .flatMap({ (error, data) -> Driver<Void> in
                if let error = error as? GooServiceError {
                    switch error {
                    case .terminalRegistration:
                        if var userInfo = AppManager.shared.userInfo.value, userInfo.deviceStatus != .unregistered {
                            userInfo.deviceStatus = .unregistered
                            AppManager.shared.userInfo.accept(userInfo)
                        }
                        
                        warningMessage.onNext(L10n.CreateFolder.Error.unregisteredDevice)
                        return Driver.empty()
                        
                    case .maintenance, .maintenanceCannotUpdate:
                        if data.folder == nil {
                            warningMessage.onNext(L10n.CreateFolder.Error.maintenance)
                        } else {
                            warningMessage.onNext(L10n.RenameFolder.Error.maintenance)
                        }
                        
                        return Driver.empty()
                        
                    case .sessionTimeOut:
                        warningMessage.onNext("")
                        // update session and call the api again
                        return self.useCase.refreshSession()
                            .trackActivity(activityIndicator)
                            .catchError({ (error) -> Observable<Void> in
                                return self.navigator
                                    .showMessage(L10n.Sdk.Error.Refresh.session)
                                    .observeOn(MainScheduler.instance)
                                    .do(onNext: self.navigator.toForceLogout)
                                    .flatMap({ Observable.empty() })
                            })
                            .do(onNext: {
                                if retry.value == 0 {
                                    retry.accept(1)
                                }
                            })
                            .asDriverOnErrorJustComplete()
                        
                    case .authenticationError:
                        warningMessage.onNext("")
                        // force log out
                        return self.useCase.logout()
                            .subscribeOn(MainScheduler.instance)
                            .do(onNext: self.navigator.toForceLogout)
                            .asDriverOnErrorJustComplete()
                        
                    case .duplicateFolder:
                        warningMessage.onNext(L10n.CreateFolder.Error.duplicate)
                        return Driver.empty()
                        
                    case .limitRegistrtion:
                        
                        var msg: String
                        if AppManager.shared.billingInfo.value.billingStatus == .paid {
                            msg = L10n.CreateFolder.Error.limitPaid
                        } else {
                            msg = L10n.CreateFolder.Error.limit
                        }
                        
                        warningMessage.onNext(msg)
                        return Driver.empty()
                        
                    case .otherError(let errorCode):
                        warningMessage.onNext("")
                        return self.navigator
                            .showMessage(errorCode: errorCode)
                            .asDriverOnErrorJustComplete()
                        
                    default:
                        warningMessage.onNext("")
                        return Driver.empty()
                    }
                }
                
                warningMessage.onNext("")
                return self.navigator
                    .showMessage(L10n.Server.Error.timeOut)
                    .asDriverOnErrorJustComplete()
            })
            .flatMap({ _ -> Driver<Void> in
                Driver.empty()
            })
        
        let userAction = dataTrigger
            .mapToVoid()
            .do(onNext: {
                retry.accept(0)
            })
            
        let retryAction = retry.asDriver()
            .filter({ $0 > 0 })
            .mapToVoid()
        
        let checkFolderName = Driver
            .merge(
                userAction,
                retryAction)
            .withLatestFrom(dataTrigger)
            .flatMap({ (data: UpdateFolderData) -> Driver<Bool> in
                // don't allow to use empty name
                if data.name.isEmpty {
                    warningMessage.onNext(L10n.Folder.emptyName)
                    return Driver.empty() // Do nothing
                }
                
                // has the same name with the selected foler
                if let currentName = data.folder?.name, data.name == currentName {
                    warningMessage.onNext("")
                    return Driver.just(true) // Close the view controll
                }
                
                // check on cloud or at local
                if data.isCloud {
                    warningMessage.onNext("")
                    return Driver.just(true)
                } else {
                    return self.useCase
                        .exists(folderName: data.name)
                        .map({ $0 == nil })
                        .do(onNext: { (notExist) in
                            if notExist {
                                warningMessage.onNext("")
                            } else {
                                warningMessage.onNext(L10n.Folder.existName)
                            }
                        })
                        .asDriverOnErrorJustComplete()
                }
            })
        
        let updateTrigger = checkFolderName
            .filter({ $0 })
            .withLatestFrom(dataTrigger)
            .map({ (name: $0.name, folder: $0.folder, isCloud: $0.isCloud) })
        
        let updatedLocalFolder = updateTrigger
            .filter({ $0.isCloud == false })
            .flatMap({ (newName, oldFolder, _) -> Driver<Void> in
                if var folder = oldFolder {
                    if folder.name == newName {
                        return Driver.just(())
                    }
                    
                    folder.name = newName
                    return self.useCase.updateFolder(folder: folder)
                        .asDriverOnErrorJustComplete()
                        .do(onNext: {
                            self.delegate.onNext(.updatedLocalFolder)
                        })
                }
                
                return self.useCase.createFolder(name: newName, manualIndex: self.valueIndex)
                    .asDriverOnErrorJustComplete()
                    .do(onNext: {
                        self.delegate.onNext(.updatedLocalFolder)
                    })
            })
        
        let updatedCloudFolder = updateTrigger
            .filter({ $0.isCloud == true })
            .flatMap({ (newName, oldFolder, _) -> Driver<Void> in
                let request: Observable<Void>
                if var folder = oldFolder {
                    if folder.name == newName {
                        return Driver.just(())
                    }
                    
                    folder.name = newName
                    request = self.useCase.updateCloudFolder(folder: folder)
                } else {
                    request = self.useCase.createCloudFolder(name: newName)
                }
                
                return request
                    .trackActivity(activityIndicator)
                    .trackError(error)
                    .asDriverOnErrorJustComplete()
                    .do(onNext: {
                        self.delegate.onNext(.updatedCloudFolder)
                        NotificationCenter.default.post(name: .didUpdateCloudFolder, object: nil)
                    })
            })
            
        
        return Driver.merge(updatedLocalFolder, updatedCloudFolder, errorHandler)
    }
}
extension NamingViewModel {
    func validate(content: String, shouldChangeTextIn range: NSRange, replacementText text: String) -> String? {
        checkText(currentText: content, maxLen: NamingUseCase.Constant.maxContent, shouldChangeTextIn: range, replacementText: text)
    }
    
    // Return nil means it's ok, if not, it will return a valid text (which has beed cut off) to replace the whole text
    private func checkText(currentText: String, maxLen: Int, shouldChangeTextIn range: NSRange, replacementText text: String) -> String? {
        var currentText = currentText
        let count = currentText.count - range.length + text.count
        if count > maxLen {
            if let start = currentText.utf16.index(currentText.startIndex, offsetBy: range.lowerBound, limitedBy: currentText.endIndex),
               let end = currentText.utf16.index(currentText.startIndex, offsetBy: range.upperBound, limitedBy: currentText.endIndex) {
                //The delacred will calculate the position that will be remove
                //And map elements String to String
                let countValid = text.count - (count - maxLen)
                let t = text.enumerated().filter{ $0.offset < countValid }.map{ $0.element }.map{ String($0) }.joined()
                currentText.replaceSubrange(start..<end, with: t)
                
                //the old handle
//                currentText.replaceSubrange(start..<end, with: text)

            }
            
            currentText = String(currentText.prefix(maxLen))
            return currentText
        }
        
        return nil
    }
}
