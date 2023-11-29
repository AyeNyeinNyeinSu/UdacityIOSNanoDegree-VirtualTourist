//
//  HTTPMethods.swift
//  VirtualTourist
//
//  Created by Aye Nyein Nyein Su on 24/05/2023.
//

import Foundation

class HTTPMethods {

    //MARK: - GET

    class func taskForGETRequest<ResponseType: Decodable>(url: URL, responseType: ResponseType.Type, completion: @escaping (ResponseType?, Error?) -> Void) {

        let task = URLSession.shared.dataTask(with: url) { data, response, error  in
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            do {
                //print(String(data: data, encoding: .utf8))
                let responseObject = try JSONDecoder().decode(ResponseType.self, from: data)
                DispatchQueue.main.async {
                    completion(responseObject, nil)
                }
            } catch let err {
                print(err)
                DispatchQueue.main.async {
                    completion(nil, err)
                }
            }
        }
        task.resume()
    }

}
