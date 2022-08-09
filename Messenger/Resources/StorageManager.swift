//
//  StorageManager.swift
//  Messenger
//
//  Created by Agata Menes on 14/07/2022.
//

import Foundation
import FirebaseStorage
import SwiftUI
import MapKit

final class StorageManager {
    
    static let  shared = StorageManager()
    
    private let storage = Storage.storage().reference()
    private let metaData = StorageMetadata()
    public typealias UploadPictureCompletion = (Result<String, Error>) -> Void
    
    /// Uploads picture to firebase storage and returs completion with url string to download
    public func uploadProfilePicture(with data: Data, fileName: String, completion: @escaping UploadPictureCompletion) {
        storage.child("images/\(fileName)").putData(data, metadata: nil, completion: { [weak self] metadata, error in
            guard let strongSelf = self else {
                return
            }
            guard error == nil else {
                print("failed to upload data to firebase for pic")
                completion(.failure(StorageErrors.failedToUplad))
                return
            }
            
            strongSelf.storage.child("images/\(fileName)").downloadURL(completion: { url, error in
                guard let url = url else {
                    print("failed To Get Download Url")
                    completion(.failure(StorageErrors.failedToGetDownloadUrl))
                    return
                }
                
                let urlString = url.absoluteString
                print("Download url returned: \(urlString)")
                completion(.success(urlString))
            })
            
        })
    }
    
    public func uploadMessagePhotoToSend(with data: Data, fileName: String, completion: @escaping UploadPictureCompletion) {
        storage.child("message_images/\(fileName)").putData(data, metadata: nil, completion: { [weak self] metadata, error in
            guard error == nil else {
                print("failed to upload message photo data to firebase")
                completion(.failure(StorageErrors.failedToUplad))
                return
            }
            
            self?.storage.child("message_images/\(fileName)").downloadURL(completion: { url, error in
                guard let url = url else {
                    print("failed To Get photo messages Download Url")
                    completion(.failure(StorageErrors.failedToGetDownloadUrl))
                    return
                }
                
                let urlString = url.absoluteString
                print("photo messages download url returned: \(urlString)")
                completion(.success(urlString))
            })
        })
    }
    
    public func uploadMessageVideoToSend(with fileUrl: URL, fileName: String, completion: @escaping UploadPictureCompletion) {
        metaData.contentType = "video/quicktime"
        
        if let videoData = NSData(contentsOf: fileUrl) as? Data {
            storage.child("message_videos/\(fileName)").putData(videoData, metadata: metaData, completion: { [weak self] metadata, error in
                print("second")
                guard error == nil else {
                    print("failed to upload video data to firebase")
                    completion(.failure(StorageErrors.failedToUplad))
                    return
                }
                
                self?.storage.child("message_video/\(fileName)").downloadURL(completion: { url, error in
                    guard let url = url else {
                        print("failed To Get video messages Download Url")
                        completion(.failure(StorageErrors.failedToGetDownloadUrl))
                        return
                    }
                    
                    let urlString = url.absoluteString
                    print("video messages download url returned: \(urlString)")
                    completion(.success(urlString))
                })
            })
        }
    }
    
    public enum StorageErrors: Error {
        case failedToUplad
        case failedToGetDownloadUrl
    }
    
    public func downloadURL(for path: String, completion: @escaping (Result<URL, Error>) -> Void) {
        let reference = storage.child(path)
        
        reference.downloadURL(completion: { url, error in
            guard let url = url, error == nil else {
                completion(.failure(StorageErrors.failedToGetDownloadUrl))
                return
            }
            completion(.success(url))
        })
    }
    
}
