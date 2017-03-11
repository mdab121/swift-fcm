// (c) 2017 Kajetan Michal Dabrowski
// This code is licensed under MIT license (see LICENSE for details)

import Foundation

/// This is the main class that you should be using to send notifications
public class Firebase {

	private lazy var urlSession: URLSession = {
		let sessionConfiguration = URLSessionConfiguration.ephemeral
		sessionConfiguration.urlCache = nil
		sessionConfiguration.urlCredentialStorage = nil
		return URLSession(configuration: sessionConfiguration)
	}()

	private let serverKey: ServerKey

	private let serializer: MessageSerializer = MessageSerializer()
	private let pushUrl: URL = URL(string: "https://fcm.googleapis.com/fcm/send")!


	/// Convenience initializer taking a path to a file where the key is stored.
	///
	/// - Parameter keyPath: Path to the Firebase Server Key
	/// - Throws: Throws an error if file doesn't exist
	public convenience init(keyPath: String) throws {
		let serverKeyString = try String(contentsOfFile: keyPath).trimmingCharacters(in: .whitespacesAndNewlines)
		self.init(serverKey: ServerKey(rawValue: serverKeyString))
	}


	/// Initializes FCM with the key as the parameter. Please note that you should NOT store your server key in the source code and in your repository.
	/// Instead, fetch your key from some configuration files, that are not stored in your repository.
	///
	/// - Parameter serverKey: server key
	public init(serverKey: ServerKey) {
		self.serverKey = serverKey
	}


	/// Sends a single message to a single device. After sending it calls the completion closure on the queue that it was called from.
	///
	/// - Parameters:
	///   - message: The message that you want to send
	///   - deviceToken: Firebase Device Token that you want to send your message to
	///   - completion: completion closure
	/// - Throws: Serialization error when the message could not be serialized
	public func send(message: Message, to deviceToken: DeviceToken, completion: @escaping (FirebaseResponse) -> Void) throws {
		let request = try generateRequest(message: message, deviceToken: deviceToken)
		let callQueue = OperationQueue.current ?? OperationQueue.main
		urlSession.dataTask(with: request) { (data, response, error) in
			// Do the parsing on the background queue
			let firebaseResponse = FirebaseResponse(data: data, statusCode: (response as? HTTPURLResponse)?.statusCode ?? 500, error: error)
			callQueue.addOperation {
				//call completion on the captured caller queue
				completion(firebaseResponse)
			}
		}.resume()
	}

	// MARK: Private methods

	private func generateRequest(message: Message, deviceToken: DeviceToken) throws -> URLRequest {
		var request = generateEmptyRequest()
		request.httpBody = Data(bytes: try serializer.serialize(message: message, device: deviceToken))
		return request
	}

	private func generateEmptyRequest() -> URLRequest {
		var request = URLRequest(url: pushUrl)
		request.httpMethod = "POST"
		for (header, value) in generateHeaders() {
			request.addValue(value, forHTTPHeaderField: header)
		}
		return request
	}

	private func generateHeaders() -> [String: String] {
		return [
			"Content-Type": "application/json",
			"Authorization": "key=\(serverKey.rawValue)"
		]
	}
}
