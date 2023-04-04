//
//  DailyBoxOfficeViewController.swift
//  BoxOffice
//
//  Created by Muri, Rowan on 13/01/23.
//

import UIKit

final class DailyBoxOfficeViewController: UIViewController {
    private let collectionView = UICollectionView(frame: UIScreen.main.bounds,
                                                  collectionViewLayout: UICollectionViewFlowLayout())
    private var dailyBoxOffice: DailyBoxOffice?
    private var yesterday: Date {
        return Date(timeIntervalSinceNow: 3600 * -24)
    }
    private var currentDate: Date?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        LoadingIndicator.showLoading()
        configureRootView()
        configureNavigationBar()
        loadDailyBoxOffice(date: yesterday)
        configureCollectionView()
        configureRefreshControl()
    }
    
    private func configureRootView() {
        view.addSubview(collectionView)
        view.backgroundColor = .white
    }
    
    private func configureNavigationBar() {
        let titleText = DateFormatter.shared.string(from: currentDate ?? yesterday,
                                                    dateFormat: "yyyy-MM-dd")
        title = titleText
        
        let dateChangeButton = UIBarButtonItem(title: "날짜선택",
                                               style: .plain,
                                               target: self,
                                               action: #selector(showCalendar))
        navigationItem.rightBarButtonItem = dateChangeButton
    }
    
    @objc func showCalendar() {
        let calendarViewController = CalendarViewController()
        navigationController?.present(calendarViewController, animated: true)
        calendarViewController.delegate = self
    }
    
    private func loadDailyBoxOffice(date: Date) {
        var api = KobisAPI(service: .dailyBoxOffice)
        let queryName = "targetDt"
        let queryValue = DateFormatter.shared.string(from: date, dateFormat: "yyyyMMdd")
        api.addQuery(name: queryName, value: queryValue)
        
        var apiProvider = APIProvider()
        apiProvider.target(api: api)
        apiProvider.startLoad(decodingType: DailyBoxOffice.self) { result in
            switch result {
            case .success(let dailyBoxOffice):
                self.dailyBoxOffice = dailyBoxOffice
                
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                    self.collectionView.refreshControl?.endRefreshing()
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    AlertController.showAlert(for: error, to: self)
                }
            }
            
            LoadingIndicator.hideLoading()
        }
    }
    
    private func configureCollectionView() {
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
        loadDailyBoxOffice(date: currentDate ?? yesterday)
        
        DispatchQueue.main.async {
            self.configureNavigationBar()
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
        
        cell.configureLabels(with: movieData)
        
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
        
        collectionView.deselectItem(at: indexPath, animated: true)
    }
}

extension DailyBoxOfficeViewController: CalendarViewControllerDelegate {
    func changeTarget(date: Date) {
        currentDate = date
        let titleText = DateFormatter.shared.string(from: date, dateFormat: "yyyy-MM-dd")
        self.navigationItem.title = titleText
        loadDailyBoxOffice(date: date)
    }
}
