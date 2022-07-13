# Mobilogy Cloud SDK for iOS: Backup & Restore

Mobilogy Cloud SDK helps to transfer  from one phone to another. It supports iOS and Android.
Telcos and Resellers can embed the Mobilogy SDK into their own application. In addition to making the upgrade process faster, it can also offer a recovery path for consumers who lose or damage their phone.

## Features
- Authentication is based on the "Sign in with Apple" and "Sign in with Google" services. 
- Authorization is provided by the AWS Cognito Services. Hence registered users will have access to the features of the SDK.
- Executes back up and restoration of various types of data.
- Data stored on the AWS cloud is encrypted by a user choosen passphrase (SSE-C).

## Solution
SDK makes use of AWS Cognito service in the backend to accomplish the user authentication with the 3rd party identity providers such as Google, Apple etc. using OAuth2.0 framework. Once the user is authenticated, the required tokens to access the AWS resources are issued by the SDK.
A secret passphrase is required to generate a 256-bit Advanced Encryption key, which is used to encrypt the user data that is uploaded to the S3 bucket. The same secret passphrase is used to backup and restore the data. 

## Installation (Cocoapods)
```ruby
source 'https://github.com/CocoaPods/Specs.git'
source "https://github.com/trilogy-group/mobilogytrans-ios-spec.git"
pod "MobilogySDK"
```
The repository is private and protected by 2-factor authentication. As CocoaPods does not currenlty support 2FA, you need to use a [Personal Access Token](https://docs.github.com/en/github/authenticating-to-github/keeping-your-account-and-data-secure/creating-a-personal-access-token)

## Prerequisites
- SDK is backed by AWS and Amplify. To use it, init Amplify in your project. Refer to Amplify documentation on how to do that. 
- SDK requires following permissions (add them to the info.plist of the project)
```xml
<key>NSCameraUsageDescription</key>
<string>This app wants to take pictures.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>This app wants to use your photos.</string>
<key>NSContactsUsageDescription</key>
<string>This app wants to use your contacts.</string>
<key>NSCalendarsUsageDescription</key>
<string>This app wants to use your calendar.</string>
```

## API Usage
### Initialization
Initialization is required before calling any other functions of the SDK. If you will call functions before initialization, you will get ```fatalError```.

```swift
let params = MobilogySDKInitParams(clientKey: "SDK_LICENSE_KEY_OF_THE_SERVICE_PROVIDER")
params.passphrase = "123" // optional
  MobilogySDK.initialize(params: params) { success: Bool, error: Error? in
    code
  }
```
NOTE: In case the passphrase is set and does not comply with the password policy, initialize will pass MobilogySDKErrorCode.failedPassphrasePolicy error to the completion handler. Passphrase follows standard policy as mentioned below:
   1. Minimum length: 8
   2. Require numbers
   3. Require special character
   4. Require uppercase letters
   5. Require lowercase letters
   
### Callbacks
API provides delegate interface for callbacks.

```swift
MobilogySDK.shared.delegate = self
extension YourClass : MobilogySDKDelegate {
    public func success(mode: ModeOfOperation) {
       code
    }
    public func failure(code: MobilogySDKErrorCode, error: Error) {
        code
    }
}
```

### Authentication

```swift
MobilogySDK.shared.executeAuth(authProvider: .apple, window: window, passphrase: "1234")
// passphrase is required here or on SDK initialization
```

On success of this call, the app will call the delegate that indicates the mode of operation. ModeOfOperation parameter will be returned to the success method. Following are the valid values ModeOfOperation that will be return in the call back:
- notEnabled : Feature not enabled
- backup: Device should be enabled only for back up operation.
- restore: Device should be enabled only for restore operation.
- both: Device should be enabled only for both backup & restore operation. And in this case the source and target is the same device where the app is installed.

On error, the following errors can be returned
- SystemAuthError: Is a general error for all other errors during authorization. Most likely this error is caused due to bottlenecks in resources requests or due to network issues. Mostly likely the app should retry authorization for this error.
- MissingDevicePermissions: It will list the set of permissions that the App does not have to execute the backup and restore funcationality.
- WrongPassphrase: Passphrase provided to the sdk was wrong.
- UnableToVerifyPassphrase: The SDK was unable to verify the passphrase due to connection issues.

At any time app can check if the user is signed in by calling ```isSignedIn(completion: @escaping (ModeOfOperation?, Error?)```:
```swift
MobilogySDK.shared.isSignedIn { modeOfOperation, error in
    if (modeOfOperation != nil) {
        //signed in
    } else {
        //not signed in
    }
}
```
SDK also provides a possibility to sign out a user by calling ```signOut(_ completion: @escaping (Bool, Error?) -> Void)```:
```swift
MobilogySDK.shared.signOut { result, error in
    if result == true {
        //user signed out
    }
}
```

### Backup Process:
- SDK provides various types of data backups that are classified as Files, Contacts & Documents. Files include Video/Photos. Contacts include your Phone contacts. Documents include files outside your app's sandbox. Before the backup, you can configure the type of backup to perform. All these options should be passed to the executeBackup API as a BackupSettings instance as shown below:
```swift
let settings = BackupSettings(
    doDocumentsBackup: true,
    doContactsBackup: true,
    doFilesBackup: true
)
let isWifiOnly = true // can be true or false depends if client enabled backup using wifi or not
MobilogySDK.shared.executeBackup(settings: settings, isWifiOnly: isWifiOnly, completion: { [weak self] result in
    guard let self = self else { return }
    switch result {
        case .success:
            // Backup started successfully
        
        case let .failure(error):
            // Handle error(show error to the client)
    }
}))
```

Sdk checks if the user is authenticated and the backup process starts with the corresponding data types. Data is uploaded to S3 cloud after encrypting with the SSE Key that was generated based on the passphrase. Once the data is uploaded, the process completes. 
NOTE: If the user is not authenticated, then the SDK will throw ```MobilogySDKErrorCode.invalidModeOfOperation``` error. This is necessary to enforce that the App goes through the Initialization & Authorization process before starting a backup process.

During the course of its execution, all the statistics of the backup process are available to the App through another API called ```retrieveCurrentStatus```.

```swift
// most likely you could use a timer for continous monitoring at regular intervals
let timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
    var stats: CategorizedStatistics = MobilogySDK.shared.retrieveCurrentStatus()
}
```
Categorized statistics object provides the folowing fields:
1. lastModifiedDate: Timestamp of the last change to the statistics of the backup process.
2. totalNoOfFiles: Total number of files in the Queue for upload.
3. totalNoOfSuccessFileCount: Number of files uploaded successfully.
4. totalNoOfFailedFileCount: Number of files that have failed an attempt to upload.
5. totalFileSizeProcessed: Total bytes that are processed by the backup process.
6. errorFiles: Array of file names that have failed upload.
7. status: OperationStatus enum with possible values: YET_TO_START, IN_PROGRESS, COMPLETED indicating current status of the backup process.
8. images: Statistics object containing information about backup of the images.
9. videos: Statistics object containing information about backup of the videos.
10. contacts: Statistics object containing information about backup of the contacts.
11. documents: Statistics object containing information about backup of the documents.
12. calendars: Statistics object containing information about backup of the calendars.

Fields ```images```, ```videos```, ```documents``` are properties of type ```Statistics``` and each contain following fields:
1. lastModifiedDate: Timestamp of the last change to the statistics of particular category.
2. totalNoOfFiles: Total number of files of particular category in the Queue for upload.
3. totalNoOfSuccessFileCount: Number of files of particular category uploaded successfully.
4. totalNoOfFailedFileCount: Number of files of particular category that have failed an attempt to upload.
5. totalFileSizeProcessed: Total bytes that are processed by the backup process.
6. errorFiles: Array of file names of particular category that have failed upload.
7. status: OperationStatus enum with possible values: YET_TO_START, IN_PROGRESS, COMPLETED representing backup status of category.

Field  ```contacts```, is a property of type  ```ContactsStatistics``` that inherits from  ```Statistics``` and additionaly conains following fields:
1. totalNoOfContacts: Total number of contacts prepared for upload.
2. totalNoOfSuccessContactCount: Number of contacts successfully uploaded .
3. totalNoOfFailedContactCount: Number of contacts that have failed an attempt to upload.

Field  ```calendars```, is a property of type  ```CalendarsStatistics``` that inherits from  ```Statistics``` and additionaly conains following fields:
1. totalNoOfEvents: Total number of calendar events prepared for upload.
2. totalNoOfSuccessEventsCount: Number of calendar events successfully uploaded .
3. totalNoOfFailedEventsCount: Number of calendar events that have failed an attempt to upload.

### Restore Process:
- Similarly to the backup, a restore process can be triggered in the background by calling executeRestore as shown below:
```swift

let isWifiOnly = true // can be true or false depends if client enabled backup using wifi or not
MobilogySDK.shared.executeBackup(settings: settings, isWifiOnly: isWifiOnly, completion: { [weak self] result in
    guard let self = self else { return }
    switch result {
        case .success:
            // Backup started successfully        
        case let .failure(error):
            // Handle error(show error to the client)
    }
})
```
NOTE: If the user is not authenticated, then the SDK will throw ```MobilogySDKErrorCode.invalidModeOfOperation``` error. This is necessary to enforce that the App goes through the Initialization & Authorization process before starting a backup process.

Similarly to the backup process, app could fetch all the statistics of the restore process through API called ```retrieveCurrentStatus```.
```swift
// most likely you could use a timer for continous monitoring at regular intervals
let timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
    var stats: CategorizedStatistics = MobilogySDK.shared.retrieveCurrentStatus()
}
```

Categorized statistics object provides the folowing fields:
1. lastModifiedDate : Timestamp of the last change to the statistics of the restore process.
2. totalNoOfFiles: Total number of files in the Queue for download.
3. totalNoOfSuccessFileCount: Number of files downloaded successfully.
4. totalNoOfFailedFileCount: Number of files that have failed an attempt to download.
5. totalFileSizeProcessed: Total bytes that are processed by the restore process
6. errorFiles: List of file names that have failed download.
7. status: OperationStatus enum with possible values: YET_TO_START, IN_PROGRESS, COMPLETED indicating current status of the restore process.
8. images: Statistics object containing information about restore of the images.
9. videos: Statistics object containing information about restore of the videos.
10. contacts: Statistics object containing information about restore of the contacts.
11. documents: Statistics object containing information about restore of the documents.
12. calendars: Statistics object containing information about restore of the calendars.

Fields ```images```, ```videos```, ```contacts```, ```documents``` are properties of type ```Statistics``` and each contain following fields:
1. lastModifiedDate: Timestamp of the last change to the statistics of particular category.
2. totalNoOfFiles: Total number of files of particular category in the Queue for download.
3. totalNoOfSuccessFileCount: Number of files of particular category downloaded successfully.
4. totalNoOfFailedFileCount: Number of files of particular category that have failed an attempt to download.
5. totalFileSizeProcessed: Total bytes that are processed by the restore process.
6. errorFiles: Array of file names of particular category that have failed download.
7. status: OperationStatus enum with possible values: YET_TO_START, IN_PROGRESS, COMPLETED representing restore status of category.

Field  ```contacts```, is a property of type  ```ContactsStatistics``` that inherits from  ```Statistics``` and additionaly conains following fields:
1. totalNoOfContacts: Total number of contacts contained in the files.
2. totalNoOfSuccessContactCount: Number of contacts successfully restored to the device.
3. totalNoOfFailedContactCount: Number of contacts that have failed to save on the device.

Field  ```calendars```, is a property of type  ```CalendarsStatistics``` that inherits from  ```Statistics``` and additionaly conains following fields:
1. totalNoOfEvents: Total number of calendar events contained in the files.
2. totalNoOfSuccessEventsCount: Number of calendar events successfully restored to the device.
3. totalNoOfFailedEventsCount: Number of calendar events that have failed to save on the device.

### Reference application:
Here is the [demo app](https://github.com/trilogy-group/mobilogytrans-ios-reference-app) with this SDK
