//
//  ContentView.swift
//  AITextToSpeech
//
//  Created by John goodstadt on 04/11/2023.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
	
	@State private var selectedVoice = "en-GB-Studio-C"
	@State var voices = ["en-GB-Studio-C", "en-US-Neural2-I"]
	@State var phrase:String = ""
	@State var results:String = ""
	@State var audioPlayer: AVAudioPlayer? //Use to play returned mp3
	@State private var showSSML = false
	
	let defaultPhrase = "This is spoken by Google's Text to Speech engine."
	let userPhrase = "Enter some words in the text box. Then hit play."
	let ssmlPhrase = """
 <speak>
  Here are <say-as interpret-as="characters">SSML</say-as> samples.
 I can pause <break time="3s"/>.
 I can speak in cardinals. Your number is <say-as interpret-as="cardinal">10</say-as>.
 Or I can speak in ordinals. You are <say-as interpret-as="ordinal">10</say-as> in line.
 Or I can even speak in digits. The digits for ten are <say-as interpret-as="characters">10</say-as>.
 I can also substitute phrases, like the <sub alias="World Wide Web Consortium">W3C</sub>.
 Finally, I can speak a paragraph with two sentences.
 <p><s>This is sentence one.</s><s>This is sentence two.</s></p>
 </speak>
 """
	init() {
		UITextField.appearance().clearButtonMode = .whileEditing
	}
	
	var body: some View {
		VStack {
			VStack {
				Text("Select a voice:")
					
				
				Picker("Select a voice to speak", selection: $selectedVoice) {
					ForEach(voices, id: \.self) {
						Text($0)
					}
				}
				.pickerStyle(.menu)
				
				Text("Tap to hear some spoken text")
					.font(.title2)
					.padding()
				
				Button(action: {
					
					GoogleSpeechManager.shared.speak(text:  defaultPhrase, voiceName: selectedVoice) {  result in
						switch result {
							case .failure(let error):print("error \(error)")
								print(error)
								results = error.localizedDescription
							case .success(let mp3):
								do{
									self.audioPlayer = try AVAudioPlayer(data: mp3 , fileTypeHint: "mp3")
									self.audioPlayer?.prepareToPlay()
									self.audioPlayer?.play()
									results = "mp3 size:\(mp3.count) bytes"
									
								}catch{
									print(error)
									results = error.localizedDescription
								}
						}
					}
					
				}) {
					ZStack {
						Image(systemName: "play.fill")
							.frame(height: 36)
							.imageScale(.large)
							.foregroundColor(.accentColor)
							.font(.system(size: 36))
						
					}
				}
				
				Divider().frame(height: 1)
					.overlay(.gray)
					.padding()
				
				HStack {
					Text("SSML")
					Toggle("SSML", isOn: $showSSML).labelsHidden()
						.onChange(of: showSSML) { value in
							if value {
								phrase = ssmlPhrase
							}else{
								phrase = ""
							}
						}
						
					Spacer()
				}

				
				ZStack(alignment: .leading) {
					
					if !showSSML {
						TextField("Enter some words", text: $phrase)
							.font(.custom("Helvetica", size: 16))
							.padding(.all)
					} else {
						TextEditor( text: $phrase)
							.font(.custom("Helvetica", size: 16))
							.padding(.all)
					}
				}
				.overlay(
						RoundedRectangle(cornerRadius: 16)
							.stroke(.gray, lineWidth: 0.6)
					)
				
				Text("Tap to speak your text")
					.font(.title2)
					.padding()
				
				Button(action: {
					let phraseToSpeak = phrase.isEmpty ? userPhrase : phrase

					GoogleSpeechManager.shared.speak(text:  phraseToSpeak, voiceName: selectedVoice) {  result in
						switch result {
							case .failure(let error):print("error \(error)")
								print(error)
								results = error.localizedDescription
							case .success(let mp3):
								do{
									self.audioPlayer = try AVAudioPlayer(data: mp3 , fileTypeHint: "mp3")
									self.audioPlayer?.prepareToPlay()
									self.audioPlayer?.play()
									results = "mp3 size:\(mp3.count) bytes"
									
								}catch{
									print(error)
									results = error.localizedDescription
								}
						}
					}
					
				}) {
					ZStack {
						Image(systemName: "play.fill")
							.frame(height: 36)
							.imageScale(.large)
							.foregroundColor(.accentColor)
							.font(.system(size: 36))
					}
				}
				Divider().frame(height: 1)
					.overlay(.gray)
					.padding()
				
				Text(results)
					.padding()
				
				Spacer()
			}
			

			
		}//: VSTACK
		.padding()
		.task {
			//GET https://texttospeech.googleapis.com/v1/voices
			//https://cloud.google.com/text-to-speech/docs/reference/rest/v1/voices/list
			
			GoogleSpeechManager.shared.getVoicesList(completion: { result in
				
				switch result {
					case .failure(let error):
						print("error \(error)")
						results = error.localizedDescription
						
					case .success(let jsonData):
						
						if let google = try? JSONDecoder().decode(Voices.self, from: jsonData) {
							print("voice count:\(google.voices.count)")
							results = "voice count:\(google.voices.count)"
							self.voices = google.voices.sorted(by: {$0.name < $1.name}).map( {$0.name} )
						}else{
							print("Error in format")
							results = "Error in format"
							print(jsonData)
						}
						
				}
			})
		}
	}
}

#Preview {
	ContentView()
}
