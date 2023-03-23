//
//  DataManagerTests.swift
//  DataManagerTests
//
//  Created by Muri, Rowan on 2023/03/20.
//

import XCTest
@testable import BoxOffice

final class DataManagerTests: XCTestCase {
    var sut: DataManager!
    
    override func setUpWithError() throws {
        sut = DataManager(kobisUrlSession: MockURLSession())
    }
    
    override func tearDownWithError() throws {
        sut = nil
    }
    
    func test_startLoadDailyBoxOfficeData호출시_date로20230101을받을때_네트워킹이_성공한경우() {
        // given
        let expectedResult = try? JSONDecoder().decode(DailyBoxOffice.self, from: KobisAPI.dailyBoxOffice.sampleData)
        
        // when
        sut.startLoadDailyBoxOfficeData(date: "20230101") { result in
            
            // then
            switch result {
            case .success(let dailyBoxOffice):
                XCTAssertEqual(dailyBoxOffice.boxOfficeResult.boxOfficeType, expectedResult?.boxOfficeResult.boxOfficeType)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        }
    }
    
    func test_startLoadDailyBoxOfficeData호출시_request가_실패한경우() {
        // given
        let expectedResult = NetworkError.request.localizedDescription
        sut = DataManager(kobisUrlSession: MockURLSession(makeRequestFail: true))
        
        // when
        sut.startLoadDailyBoxOfficeData(date: "20230101") { result in
            
            // then
            switch result {
            case .success(_):
                XCTFail()
            case .failure(let error):
                XCTAssertEqual(error.localizedDescription, expectedResult)
            }
        }
    }
    
    func test_startLoadDailyBoxOfficeData호출시_server에러가_발생한경우() {
        // given
        let expectedResult = NetworkError.server.localizedDescription
        sut = DataManager(kobisUrlSession: MockURLSession(makeServerError: true))
        
        // when
        sut.startLoadDailyBoxOfficeData(date: "20230101") { result in
            
            // then
            switch result {
            case .success(_):
                XCTFail()
            case .failure(let error):
                XCTAssertEqual(error.localizedDescription, expectedResult)
            }
        }
    }
}