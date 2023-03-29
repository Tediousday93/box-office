//
//  DailyBoxOfficeViewController.swift
//  BoxOffice
//
//  Created by Muri, Rowan on 13/01/23.
//

import UIKit

final class DailyBoxOfficeViewController: UIViewController {
    private var collectionView = UICollectionView(frame: UIScreen.main.bounds,
                                                  collectionViewLayout: UICollectionViewFlowLayout())
    private var dailyBoxOffice: DailyBoxOffice?
    private var yesterday: Date {
           return Date(timeIntervalSinceNow: 3600 * -24)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        LoadingIndicator.showLoading()
        setNavigationTitle()
        loadDailyBoxOffice()
        configureCollectionView()
        configureRefreshControl()
    }
    
    private func setNavigationTitle() {
        let title = DateFormatter(dateFormat: "yyyy-MM-dd").string(from: yesterday)
        self.title = title
        self.view.backgroundColor = .white
    }
    
    private func loadDailyBoxOffice() {
        var api = KobisAPI(service: .dailyBoxOffice)
        let queryName = "targetDt"
        let queryValue = DateFormatter(dateFormat: "yyyyMMdd").string(from: yesterday)
        api.addQuery(name: queryName, value: queryValue)
        
        var apiProvider = APIProvider()
        apiProvider.target(api: api)
        apiProvider.startLoad(decodingType: DailyBoxOffice.self) { result in
            switch result {
            case .success(let dailyBoxOffice):
                self.dailyBoxOffice = dailyBoxOffice
                
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                    LoadingIndicator.hideLoading()
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self.makeAlert(to: error)
                    LoadingIndicator.hideLoading()
                }
            }
        }
    }
    
    private func makeAlert(to error: Error) {
        let alert = UIAlertController(title: NetworkError.title, message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "닫기", style: .default))
        self.present(alert, animated: true)
    }
    
    private func configureCollectionView() {
        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])
        
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(DailyBoxOfficeCell.self,
                                forCellWithReuseIdentifier: DailyBoxOfficeCell.identifier)
    }
    
    private func configureRefreshControl() {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handlerRefreshControl), for: .valueChanged)
        collectionView.refreshControl = refreshControl
    }
    
    @objc func handlerRefreshControl() {
        loadDailyBoxOffice()
        
        DispatchQueue.main.async {
            self.setNavigationTitle()
            self.collectionView.refreshControl?.endRefreshing()
        }
    }
}

extension DailyBoxOfficeViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        guard let dailyBoxOffice = self.dailyBoxOffice else { return 0 }
        
        return dailyBoxOffice.boxOfficeResult.dailyBoxOfficeList.count
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DailyBoxOfficeCell.identifier,
                                                            for: indexPath) as? DailyBoxOfficeCell,
              let movieData = dailyBoxOffice?.boxOfficeResult.dailyBoxOfficeList[indexPath.item] else {
            return UICollectionViewCell()
        }
        
        cell.setBorder()
        cell.configureSubviews()
        cell.fillLabels(with: movieData)
        
        return cell
    }
}

extension DailyBoxOfficeViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.bounds.width, height: view.bounds.height / 10)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let navigationController = self.navigationController
        guard let movieCode = dailyBoxOffice?.boxOfficeResult.dailyBoxOfficeList[indexPath.item].movieCode,
              let movieName = dailyBoxOffice?.boxOfficeResult.dailyBoxOfficeList[indexPath.item].movieName else { return }
        let movieDetailsViewController = MovieDetailsViewController(movieCode: movieCode, movieName: movieName)
        
        navigationController?.pushViewController(movieDetailsViewController, animated: true)
    }
}
