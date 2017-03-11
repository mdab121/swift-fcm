// (c) 2017 Kajetan Michal Dabrowski
// This code is licensed under MIT license (see LICENSE for details)

public enum FirebaseError: Error {

	//TODO: There are more types of errors returned by Firebase.
	// Support them all in the future :)
	
	case invalidJson			//Firebase reported invalid payload. Please report this
	case invalidServerKey		//Pretty self explanatory
	case serverError			//Internal Firebase error

	case invalidRegistration	//Invalid Device token
	case missingRegistration	//No token
	case notRegistered

	case invalidData
	case unknown				//Unknown error

	case other(error: Error)	//Some other error – for example no internet connection
	case multiple(errors: [FirebaseError])	// Multiple nested errors

	init(message: String) {
		switch message {
		case "InvalidRegistration":
			self = .invalidRegistration
		case "MissingRegistration":
			self = .missingRegistration
		case "NotRegistered":
			self = .notRegistered
		default:
			self = .unknown
		}
	}

	init?(multiple: [FirebaseError]) {
		if multiple.isEmpty { return nil }
		if multiple.count == 1 { self = multiple.first! }
		self = .multiple(errors: multiple)
	}

	init?(statusCode: Int) {
		switch statusCode {
		case 400:
			self = .invalidJson
		case 401:
			self = .invalidServerKey
		case 500...599:
			self = .serverError
		default:
			return nil
		}
	}
}
