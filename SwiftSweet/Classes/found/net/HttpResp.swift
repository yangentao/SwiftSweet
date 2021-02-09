//
// Created by yangentao on 2019/10/27.
// Copyright (c) 2019 yangentao. All rights reserved.
//

import Foundation

extension HTTPURLResponse {
	var contentType: String? {
		self.allHeaderFields[HttpHeader.ContentType.rawValue] as? String
	}
}

public class HttpResp {
	public let response: HTTPURLResponse?
	public let content: Data?
	public let error: Error?
	public let contentType: String?

	init(response: HTTPURLResponse?, data: Data?, error: Error?) {
		self.response = response
		self.content = data
		self.error = error
		//self.contentType = response?.value(forHTTPHeaderField: HttpHeader.ContentType.rawValue)?.lowercased()
		self.contentType = response?.contentType

	}
}

public extension HttpResp {

	var statusCode: Int {
		if error != nil {
			return -1
		}
		return response?.statusCode ?? -1
	}

	var OK: Bool {
		statusCode >= 200 && statusCode < 300
	}
	var message: String? {
		if self.error != nil {
			return self.error?.localizedDescription
		} else {
			return httpMsgByCode(statusCode)
		}
	}

	var text: String? {
		if OK {
			if let dt = content {
				let encName = response?.textEncodingName ?? "UTF-8"
				if let enc = String.Encoding.fromName(encName) {
					return String(data: dt, encoding: enc)
				}
			}
		}
		return nil
	}
}

public extension HttpResp {
	func save(filePath: String, overideFile: Bool) -> Bool {
		self.save(toUrl: URL(fileURLWithPath: filePath, isDirectory: false), overideFile: overideFile)
	}

	func save(toUrl: URL, overideFile: Bool) -> Bool {
		if self.OK {
			if let d = self.content {
				do {
					if overideFile {
						try d.write(to: toUrl, options: [.atomic])
					} else {
						try d.write(to: toUrl, options: [.atomic, .withoutOverwriting])
					}
					return true
				} catch {
					print(error)
				}
			}
		}
		return false
	}

}

public extension HttpResp {
	func dump() {
		if !isDebug {
			return
		}
		println()
		let code = self.statusCode
		if code > 0 {
			println("Http Status: ", code, HTTPURLResponse.localizedString(forStatusCode: code))
		} else {
			println("Http Status2: ", code, self.message ?? "")
		}
		if let r = self.response {
			for (k, v) in r.allHeaderFields {
				println(k, ":", v)
			}
		}
		if let ct = self.contentType {
			if ct.contains("xml") || ct.contains("json") || ct.contains("html") || ct.contains("text") {
				if let s = self.text {
					println("Body:")
					println(s)
				}
			}
		} else {
			if let s = self.text {
				println("Body:")
				println(s)
			}
		}
		println("")
	}

}