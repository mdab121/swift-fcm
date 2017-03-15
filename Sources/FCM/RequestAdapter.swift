// (c) 2017 Kajetan Michal Dabrowski
// This code is licensed under MIT license (see LICENSE for details)

import Foundation

/// This is a protocol that will wrap a url http post request. It should be done by URLSession (obviously), but
internal protocol RequestAdapting {
	func send(data: Data, headers: [String: String], url: URL, completion: @escaping (Data?, Int?, Error?) -> Void) throws
}

internal class RequestAdapterCurl: RequestAdapting {

	/// :(
	private let parser = CavemanHTTPResponseParser()

	func send(data: Data, headers: [String : String], url: URL, completion: @escaping (Data?, Int?, Error?) -> Void) throws {
		//I feel safer using separate Curl handle for each request. Maybe that's not the right solution?
		let curlHelper = CurlHelper()
		let bytes = [UInt8](data)
		guard let responseData = try curlHelper.send(bytes: bytes, headers: headers, url: url.absoluteString) else {
			throw FirebaseError.invalidData
		}
		do {
			let (responseData, responseStatus) = try parser.parse(response: responseData)
			completion(responseData, responseStatus, nil)
		} catch CavemanResponseParserError.networkError(message: let message) {
			completion(nil, nil, FirebaseError.networkError(message: message))
		} catch {
			completion(nil, nil, FirebaseError.unknown)
		}
	}
}


/// This is a nice and simple implementation, but unfortunately URLSession is not yet complete, so DataTasks cannot be used.
/// It will be uses once it's complete, now we have to stickt to our caveman solution above :)
internal class RequestAdapterUrlSession: RequestAdapting {

	private lazy var urlSession: URLSession = {
		let sessionConfiguration = URLSessionConfiguration.ephemeral
		sessionConfiguration.urlCache = nil
		sessionConfiguration.urlCredentialStorage = nil
		return URLSession(configuration: sessionConfiguration)
	}()

	func send(data: Data, headers: [String : String], url: URL, completion: @escaping (Data?, Int?, Error?) -> Void) throws {
		let request = geneareRequest(data: data, headers: headers, url: url)
		let queue = OperationQueue.current ?? OperationQueue.main
		urlSession.dataTask(with: request) { (data, response, error) in
			queue.addOperation {
				completion(data, (response as? HTTPURLResponse)?.statusCode, error)
			}
		}
	}

	private func geneareRequest(data: Data, headers: [String: String], url: URL) -> URLRequest {
		var request = URLRequest(url: url)
		request.httpMethod = "POST"
		for (header, value) in headers {
			request.addValue(value, forHTTPHeaderField: header)
		}
		request.httpBody = data
		return request
	}
}
