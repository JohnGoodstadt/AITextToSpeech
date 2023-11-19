//
//  Voices.swift
//  AITextToSpeech
//
//  Created by John goodstadt on 04/11/2023.
//

import Foundation

// MARK: - Voices
//Decode return from Google API as a list of "Voice"'s
struct Voices: Codable {
	let voices: [Voice]
}

// MARK: - Voice - 4 parts
struct Voice: Codable, Hashable {
	let languageCodes: [LanguageCode]
	let name: String
	let ssmlGender: SsmlGender
	let naturalSampleRateHertz: Int
}

//Prefixed language codes of interest to us
enum LanguageCode: String, Codable {
	case enGB = "en-GB"
	case enUS = "en-US"
	case enAU = "en-AU"
	case enCA = "en-CA"
	case enIN = "en-IN"
}

//Usd to determine gender
enum SsmlGender: String, Codable {
	case female = "FEMALE"
	case male = "MALE"
	
	var prefix:String {
		String(self.rawValue.prefix(1).lowercased())
	}
}
