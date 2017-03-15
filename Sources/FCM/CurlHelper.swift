// (c) 2017 Kajetan Michal Dabrowski
// This code is licensed under MIT license (see LICENSE for details)

import Foundation
import CCurl

final internal class CurlHelper {

	private let curlHandle: UnsafeMutableRawPointer
	private var writeStorage: Data

	init() {
		curlHandle = curl_easy_init()
		curlHelperSetOptBool(curlHandle, CURLOPT_VERBOSE, CURL_FALSE)
		curlHelperSetOptBool(curlHandle, CURLOPT_POST, CURL_TRUE)
		writeStorage = Data()
	}

	deinit {
		curl_easy_cleanup(curlHandle)
	}

	func send(bytes: [UInt8], headers: [String: String], url: String) throws -> Data? {

		// Configure URL
		guard let cString = url.cString(using: .utf8) else { throw FirebaseError.unknown }
		let urlStringPointer = UnsafeMutablePointer(mutating: cString)
		curlHelperSetOptString(curlHandle, CURLOPT_URL, urlStringPointer)

		// Configure URL
		let curlHeaders = generateHeaders(headers: headers)
		curlHelperSetOptBool(curlHandle, CURLOPT_HEADER, CURL_TRUE)
		curlHelperSetOptHeaders(curlHandle, curlHeaders)

		// Configure payload
		var postFieldsString = Data(bytes: bytes)
		postFieldsString.withUnsafeMutableBytes { (t: UnsafeMutablePointer<Int8>) -> Void in
			curlHelperSetOptString(curlHandle, CURLOPT_POSTFIELDS, t)
		}
		curlHelperSetOptInt(curlHandle, CURLOPT_POSTFIELDSIZE, postFieldsString.count)

		curlHelperSetOptWriteFunc(curlHandle, &writeStorage) { (ptr, size, nMemb, privateData) -> Int in
			guard let ptr = ptr else { fatalError("Invalid pointer from CURL. Please report this") }
			guard let privateData = privateData else { fatalError("Invalid buffer from CURL. Please report this") }
			let storage = privateData.assumingMemoryBound(to: Data.self)
			let realsize = size * nMemb
			storage.pointee.append(UnsafeRawPointer(ptr).assumingMemoryBound(to: UInt8.self), count: realsize)
			return realsize
		}

		let returnStatus = curl_easy_perform(curlHandle)
		if returnStatus == CURLE_OK {
			return writeStorage
		} else {
			guard let error = curl_easy_strerror(returnStatus) else {
				throw FirebaseError.unknown
			}
			guard let errorString = String(utf8String: error) else {
				throw FirebaseError.unknown
			}
			return errorString.data(using: .utf8)
		}
	}

	private func generateHeaders(headers: [String: String]) -> UnsafeMutablePointer<curl_slist>? {
		var curlHeaders: UnsafeMutablePointer<curl_slist>? = nil
		for (key, value) in headers {
			curlHeaders = curl_slist_append(curlHeaders, "\(key): \(value)")
		}
		return curlHeaders
	}
}
