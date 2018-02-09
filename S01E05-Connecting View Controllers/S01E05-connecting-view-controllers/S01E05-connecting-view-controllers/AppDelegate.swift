//
//  AppDelegate.swift
//  S01E05-connecting-view-controllers
//
//  Created by Seal on 2018/2/10.
//  Copyright © 2018年 Shile. All rights reserved.
//

import UIKit

struct Episode {
    var title: String
}

class ProfileViewController: UIViewController {
    var person: String = ""
    var didTapClose: () -> () = {}
    @IBAction func close(sender: AnyObject) {
        didTapClose()
    }
}

class DetailViewController: UIViewController {
    var episode: Episode?
    @IBOutlet weak var label: UILabel? {
        didSet {
            label?.text = episode?.title
        }
    }
}

class EpisodesViewController: UITableViewController {
    let episodes = [Episode(title: "Episode One"), Episode(title: "Episode Two"), Episode(title: "Episode Three")]
    var didSelect: (Episode) -> () = { _ in }
    var didTapProfile: () -> () = {}
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return episodes.count
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let episode = episodes[indexPath.row]
        cell.textLabel?.text = episode.title
        return cell
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let episode = episodes[indexPath.row]
        didSelect(episode)
    }
    @IBAction func showProfile(sender: AnyObject) {
        didTapProfile()
    }
}

final class App {
    let storyboard = UIStoryboard(name: "Main", bundle: nil)
    let navigationController: UINavigationController
    
    init(window: UIWindow) {
        navigationController = window.rootViewController as! UINavigationController
        let episodeVC = navigationController.viewControllers[0] as! EpisodesViewController
        episodeVC.didSelect = showEpisode
        episodeVC.didTapProfile = showProfile
    }
    func showEpisode(episode: Episode) {
        let detailVC = storyboard.instantiateViewController(withIdentifier: "Detail") as! DetailViewController
        detailVC.episode = episode
        navigationController.pushViewController(detailVC, animated: true)
    }
    func showProfile() {
        let profileNC = storyboard.instantiateViewController(withIdentifier: "Profile") as! UINavigationController
        let profileVC = profileNC.viewControllers[0] as! ProfileViewController
        profileVC.didTapClose = {
            self.navigationController.dismiss(animated: true, completion: nil)
        }
        navigationController.present(profileNC, animated: true, completion: nil)
    }
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var app: App?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        if let window = window {
            app = App(window: window)
        }
        return true
    }
}

