# Whistle-Recorder

## Features

An iOS app to demonstrate the use case of CloudKit, AVFoundation, and Push Notification.  Registers the user's whistle and allows it to be uploaded to the public iCloud shared by all users of the app.  A user can subscribe to a certain genre of whistle to be notified upon creation.

### CloudKit

The CloudKit framework provides interfaces for moving data between your app and your iCloud containers. You use CloudKit to take your app’s existing data and store it in the cloud so that the user can access it on multiple devices. You can also store data in a public area where all users can access it.

CloudKit is not a replacement for your app’s existing data objects. Instead, CloudKit provides complementary services for managing the transfer of data to and from iCloud servers. Because it provides minimal offline caching support, CloudKit relies on the presence of the network and optionally a valid iCloud account. (A valid iCloud account is required only when you want to save data that is specific to a single user.) Apps can always store data in a public area that is readable by all users.
Records are at the heart of all data transactions in CloudKit. A record is a dictionary of key-value pairs that represents the data you want to save. You can add new keys and values to records at any time, and you can create links between related records to organize your data. The CKRecord class defines the interfaces for managing the contents of records. CloudKit also relies heavily on the use of Operation objects to manage the asynchronous transfer of data to and from the server. ([Source](https://developer.apple.com/documentation/cloudkit))

#### Related Classes

* NSPredicate describes a filter that we'll use to decide which results to show.
* NSSortDescriptor tells CloudKit which field we want to sort on, and whether we want it ascending or descending.
* CKQuery combines a predicate and sort descriptors with the name of the record type we want to query. That will be "Whistles" for this project.
* CKQueryOperation is the work horse of CloudKit data fetching, executing a query and returning results.

([Source](https://www.hackingwithswift.com/read/33/6/reading-from-icloud-with-cloudkit-ckqueryoperation-and-nspredicate))

#### API’s

CloudKit provides two different API’s: the Core API and the Convenience API.  Former exposes all the behaviours of CloudKit whereas the latter is only the subset of it.  We’re going to be using the Core API to download the content from iCloud because we want to have a fine-grained control of what we download to prevent wasting the limited resource we can use in iCloud.  There is no reason to control the upload in such a manner so we use the Convenient API for uploading to iCloud. 

##### Core API

```
let pred = NSPredicate(value: true)
let sort = NSSortDescriptor(key: "creationDate", ascending: false)
let query = CKQuery(recordType: "Whistles", predicate: pred)
query.sortDescriptors = [sort]

let operation = CKQueryOperation(query: query)
operation.desiredKeys = ["genre", "comments"]
operation.resultsLimit = 50

var newWhistles = [Whistle]()

operation.recordFetchedBlock = { record in
    let whistle = Whistle()
    whistle.recordID = record.recordID
    whistle.genre = record["genre"]
    whistle.comments = record["comments"]
    newWhistles.append(whistle)
}

operation.queryCompletionBlock = { [unowned self] (cursor, error) in
    DispatchQueue.main.async {
        if error == nil {
            ViewController.isDirty = false
            self.whistles = newWhistles
            self.tableView.reloadData()
        } else {
            let ac = UIAlertController(title: "Fetch failed", message: "There was a problem fetching the list of whistles; please try again: \(error?.localizedDescription)", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(ac, animated: true)
        }
    }
}

CKContainer.default().publicCloudDatabase.add(operation)
```

##### Convenience API

- performQuery()
```
CKContainer.default().publicCloudDatabase.perform(query, inZoneWith: nil) { [unowned self] results, error in
    if let error = error {
        print(error.localizedDescription)
    } else {
        if let results = results {
            self.parseResults(records: results)
        }
    }
}
```

- fetch(withRecordID: )
```
    CKContainer.default().publicCloudDatabase.fetch(withRecordID: whistle.recordID) { [unowned self] record, error in
        if let error = error {
            DispatchQueue.main.async {
                // meaningful error message here!
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Download", style: .plain, target: self, action: #selector(self.downloadTapped))
            }
        } else {
            if let record = record {
                if let asset = record["audio"] as? CKAsset {
                    self.whistle.audio = asset.fileURL

                    DispatchQueue.main.async {
                        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Listen", style: .plain, target: self, action: #selector(self.listenTapped))
                    }
                }
            }
        }
    }
```

### publicCloudDatabase

Public iCloud is available regardless of whether the user’s device has an active iCloud account. The contents of the public database are readable by all users of the app, and users have write access to the records (and other data objects) they create. Data in the public database is also visible in the developer portal, where you can assign roles to users and restrict access as needed.

Data stored in the public database counts against your app’s iCloud storage quota and not against the quota of any single user. ([Source](https://developer.apple.com/documentation/cloudkit/ckcontainer/1399166-publicclouddatabase))

### UIStackView

UIStackView primarily makes resizing and positioning of the arranged subviews easy for us by applying the Auto Layout on behalf of us.  The benefit of this UIStackView doesn’t just apply upon the initial load of the view controller.  We can dynamically add and subtract the subviews any time after the initial load and UIStackView will still take care of the resizing and positioning for us.  This allows us to make use of appearing and disappearing animations for the UI elements like UILabels or UIButtons.  

One important thing to remember for stack views is that you have to make use of the isHidden and the alpha property both in order to properly make appearing/disappearing happen.  This is because even if isHidden is set to true, the subview within the stack view still occupies its space.  You have to make sure that alpha is also set to 0

```
playButton = UIButton()
playButton.translatesAutoresizingMaskIntoConstraints = false
playButton.setTitle("Tap to Play", for: .normal)
playButton.isHidden = true
playButton.alpha = 0
playButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .title1)
playButton.addTarget(self, action: #selector(playTapped), for: .touchUpInside)
stackView.addArrangedSubview(playButton)
```

### Table View Cell

If you want to define the prototype cell programmatically, you have to change the Prototype Cells from 1 to 0 in the Attributes Inspector of Table View 

<img src="https://github.com/igibliss00/Whistle-Recorder/blob/master/README_assets/1.png" width="400">

And register the “Cell” re-use identifier:

```
override func viewDidLoad() {
    super.viewDidLoad()
    
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
}

```

We can now use this identifier to modify the cell’s properties, such as numberOfLines or accessoryType, like you’d normally do with Interface Builder:

```
override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
    cell.accessoryType = .disclosureIndicator
    cell.textLabel?.attributedText = makeAttributedString(title: whistles[indexPath.row].genre, subtitle: whistles[indexPath.row].comments)
    cell.textLabel?.numberOfLines = 0
    
    return cell
}

```
