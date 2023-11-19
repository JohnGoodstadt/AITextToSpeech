//
//  GoogleSpeechManager.swift
//  Google Speech API Demo
//
//  Created by John goodstadt on 04/11/2023.
//

import UIKit


fileprivate let ttsAPIUrl = "https://texttospeech.googleapis.com/v1beta1/text:synthesize"
fileprivate let APIKey = "Your Google Key"

class GoogleSpeechManager: NSObject {
	
	enum GoogleSpeechManagerError: Error {
		case busyError
		case returnedDataBadFormat
		case invalidResponseError
	}
	
	static let shared = GoogleSpeechManager()
	private(set) var busy: Bool = false//NOTE: only UI busy not Google
	
	
	//use params to call and then return the MP3 in Data format.
	func speak(text: String, voiceName:String, completion: @escaping ((Result<Data, Error>)) -> Void) {
		
		guard !text.isEmpty else {
			print("No Text to speak")
			return
		}
		
		guard !self.busy else {
			print("App is already waiting to hear from the Speech Service. Try starting again")
			completion(.failure(GoogleSpeechManagerError.busyError))
			return
		}
		
		self.busy = true
		
		DispatchQueue.global(qos: .background).async {
			let postData = self.buildPost(text: text, voiceName: voiceName)
			let headers = ["X-Goog-Api-Key": APIKey, "Content-Type": "application/json; charset=utf-8"]
			let response = self.makeRequest(url: ttsAPIUrl, postData: postData, headers: headers)
			
			// Get the `audioContent` (as a base64 encoded string) from the response.
			guard let audioContent = response["audioContent"] as? String else {
				print("Invalid response: \(response)")
				self.busy = false
				DispatchQueue.main.async {
					completion(.failure(GoogleSpeechManagerError.invalidResponseError))
				}
				return
			}
			
			// Decode the base64 string into a Data object
			guard let audioData = Data(base64Encoded: audioContent) else {
				self.busy = false
				DispatchQueue.main.async {
					completion(.failure(GoogleSpeechManagerError.returnedDataBadFormat))
				}
				return
			}
			
			DispatchQueue.main.async {
				self.busy = false
				completion(.success(audioData))
				
			}
		}
	}
	
	func getVoicesList(languageCode:String = "en",completion: @escaping ((Result<Data, Error>)) -> Void) {
		
		/*
		 GET https://texttospeech.googleapis.com/v1/voices?languageCode=en-GB&key=[YOUR_API_KEY] HTTP/1.1
		 
		 Authorization: Bearer [YOUR_ACCESS_TOKEN]
		 Accept: application/json
		 
		 */
		
		if let url = URL(string: "https://texttospeech.googleapis.com/v1/voices?languageCode=\(languageCode)&key=\(APIKey)") {
			let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
				guard let data = data else {
					//print(error)
					DispatchQueue.main.async {
						completion(.failure(GoogleSpeechManagerError.invalidResponseError))
					}
					return
				}
				completion(.success(data))
			}
			task.resume()
		}
	}
	private func buildPost(text: String, voiceName:String) -> Data {
		
		var langCode = voiceName.prefix(5)
		if langCode.count != 5 {
			langCode = "en-GB" //defensive programming - just in case
		}
		
		var voiceParams: [String: Any] = [
			"languageCode": langCode
		]
		
		guard voiceName != "Not Available" else{
			print("No voice available")
			return Data()
		}
		
		if voiceName != "Not Available" {
			voiceParams["name"] = voiceName
		}
		
		
		var synthesisInput = "text"
		if text.prefix(7) == "<speak>" {
			synthesisInput = "ssml"
		}
		
		let params: [String: Any] = [
			"input": [
				synthesisInput: text
			],
			"voice": voiceParams,
			"audioConfig": [
				// All available formats here: https://cloud.google.com/text-to-speech/docs/reference/rest/v1beta1/text/synthesize#audioencoding
				"audioEncoding": "LINEAR16"
//				"audioEncoding": "MP3" //higher quality - larger and more expensive
			]
		]
		
		// Convert the Dictionary to Data
		let data = try! JSONSerialization.data(withJSONObject: params)
		return data
	}
	
	
	// Use dataTask to call API
	private func makeRequest(url: String, postData: Data, headers: [String: String] = [:]) -> [String: AnyObject] {
		var dict: [String: AnyObject] = [:]
		
		var request = URLRequest(url: URL(string: url)!)
		request.httpMethod = "POST"
		request.httpBody = postData
		
		for header in headers {
			request.addValue(header.value, forHTTPHeaderField: header.key)
		}
		
		let semaphore = DispatchSemaphore(value: 0)
		
		let task = URLSession.shared.dataTask(with: request) { data, response, error in
			if let data = data, let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: AnyObject] {
				dict = json
			}
			
			semaphore.signal()
		}
		
		task.resume()
		_ = semaphore.wait(timeout: DispatchTime.distantFuture)
		
		return dict
	}
	
	
}
