//
//  ViewController.swift
//  AudioPlaybackManager
//
//  Created by LiuMing on 03/30/2023.
//  Copyright (c) 2023 LiuMing. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    private lazy var audioURLs: [URL] = {
        var URLs: [URL] = []
        if let enumerator = FileManager.default.enumerator(
            at: Bundle.main.bundleURL,
            includingPropertiesForKeys: nil,
            options: [],
            errorHandler: nil
        ) {
            enumerator.forEach { element in
                if let url = element as? URL, url.pathExtension == "m4a" {
                    URLs.append(url)
                }
            }
        }
        
        let onlinePaths = [
            "https://audio-ssl.itunes.apple.com/itunes-assets/AudioPreview115/v4/68/f0/a3/68f0a304-740e-68b5-b539-625ac3251938/mzaf_1764651737006700035.plus.aac.p.m4a"
        ]
        onlinePaths.forEach { path in
            if let url = URL(string: path) {
                URLs.append(url)
            }
        }
        return URLs
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSubviews()
        makeConstraints()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func setupSubviews() {
        title = "Audios"
        
        view.addSubview(tableView)
    }
    
    private lazy var tableView: UITableView = {
        let view = UITableView(frame: .zero, style: .plain)
        view.delegate = self
        view.dataSource = self
        
        view.estimatedSectionHeaderHeight = 0
        view.estimatedSectionFooterHeight = 0
        view.estimatedRowHeight = 0
        
        view.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        return view
    }()
    
    private func makeConstraints() {
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

// MARK: UITableViewDataSource
extension ViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return audioURLs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let data = audioURLs[indexPath.item]
        cell.textLabel?.text = data.lastPathComponent
        return cell
    }
}

// MARK: UITableViewDelegate
extension ViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let vc = PlayAudioViewController(audioURLs: audioURLs, defaultPlayIndex: indexPath.item)
        navigationController?.pushViewController(vc, animated: true)
    }
}
