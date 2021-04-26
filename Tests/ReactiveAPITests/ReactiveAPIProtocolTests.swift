import XCTest
import RxBlocking
@testable import ReactiveAPI

class ReactiveAPIProtocolTests: XCTestCase {

    func test_RxDataRequest_When401WithAuthenticator_DataIsValid() {
        let session = URLSessionMock.create(Resources.json, errorCode: 401)
        let api = ReactiveAPI(session: session,
                              decoder: JSONDecoder(),
                              baseUrl: Resources.url)
        api.authenticator = AuthenticatorMock(code: 401)

        do {
            let response = try api.rxDataRequest(Resources.urlRequest)
                .waitForCompletion()
                .first

            XCTAssertNotNil(response)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func test_RxDataRequest_When500WithAuthenticator_ReturnError() {
        let session = URLSessionMock.create(Resources.json, errorCode: 500)
        let api = ReactiveAPI(session: session,
                              decoder: JSONDecoder(),
                              baseUrl: Resources.url)
        api.authenticator = AuthenticatorMock(code: 401)

        do {
            _ = try await(api.rxDataRequest(Resources.urlRequest))

            XCTFail("This should throw an error!")
        } catch {
            if case let ReactiveAPIError.httpError(request: _, response: response, data: _) = error {
                XCTAssertTrue(response.statusCode == 500)
            } else {
                XCTFail("This should be a ReactiveAPIError.httpError")
            }
        }
    }

    func test_RxDataRequest_Cache() {
        let session = URLSessionMock.create(Resources.json)
        let api = ReactiveAPI(session: session,
                              decoder: JSONDecoder(),
                              baseUrl: Resources.url)
        let cache = CacheMock()
        api.cache = cache
        let request = Resources.urlRequest
        do {
            _ = try await(api.rxDataRequest(request))

            let urlCache = session.configuration.urlCache
            XCTAssertNotNil(urlCache?.cachedResponse(for: request))
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func test_RxDataRequestDecodable_WhenResponseIsValid_ReturnDecoded() {
        let session = URLSessionMock.create(Resources.jsonResponse)
        let api = ReactiveAPI(session: session,
                              decoder: JSONDecoder(),
                              baseUrl: Resources.url)
        do {
            let response: ModelMock = try api.rxDataRequest(Resources.urlRequest)
                .waitForCompletion()
                .first
                .map { $0 as ModelMock }!

            XCTAssertNotNil(response)
            XCTAssertEqual(response.name, "Patrick")
            XCTAssertEqual(response.id, 5)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func test_RxDataRequestDecodable_WhenResponseIsInvalid_ReturnError() {
        let session = URLSessionMock.create(Resources.jsonInvalidResponse)
        let api = ReactiveAPI(session: session,
                              decoder: JSONDecoder(),
                              baseUrl: Resources.url)
        do {
            let _: ModelMock = try await(api.rxDataRequest(Resources.urlRequest))
            XCTFail("This should throw an error!")
        } catch {
            if case let ReactiveAPIError.decodingError(underlyingError: underlyingError) = error {
                XCTAssertNotNil(underlyingError)
            } else {
                XCTFail("This should be a ReactiveAPIError.decodingError")
            }
        }
    }

    func test_RxDataRequestVoid_WhenResponseIsValid_ReturnDecoded() {
        let session = URLSessionMock.create(Resources.jsonResponse)
        let api = ReactiveAPI(session: session,
                              decoder: JSONDecoder(),
                              baseUrl: Resources.url)
        do {
            let response: Void = try api.rxDataRequestDiscardingPayload(Resources.urlRequest)
                .waitForCompletion()
                .first!

            XCTAssertNotNil(response)

        } catch {
            XCTFail(error.localizedDescription)
        }
    }
}
