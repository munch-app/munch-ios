//
//  MunchClientTests.swift
//  Munch
//
//  Created by Fuxing Loh on 27/3/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import Foundation
import XCTest
@testable import Munch

class MunchClientTests: XCTestCase {
    
    let client = MunchClient()
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    private func asyncTest(closure: (_ expect: XCTestExpectation) -> Void) {
        let expect = expectation(description: "Async Test")
        closure(expect)
        waitForExpectations(timeout: 10) { error in
            if let error = error {
                XCTFail("Wait timeout errored: \(error)")
            }
        }
    }
    
    func testDiscover() {
        asyncTest { (expect) in
            client.discover(){ meta, places in
                if (meta.isOk()){
                    for place in places {
                        print(place.name!)
                    }
                }else{
                    print(meta)
                }
                expect.fulfill()
            }
        }
    }
    
}
