import Foundation

/// MockURLProtocol dùng để chặn (intercept) và giả lập network response cho URLSession trong Integration Tests
public final class MockURLProtocol: URLProtocol, @unchecked Sendable {
    public typealias RequestHandler = (URLRequest) throws -> (HTTPURLResponse, Data?)

    public static var requestHandler: RequestHandler?

    override public class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override public class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override public func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            client?.urlProtocol(self, didFailWithError: NSError(
                domain: "MockURLProtocol",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Chưa cấu hình requestHandler cho MockURLProtocol"]
            ))
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)

            if let data = data {
                client?.urlProtocol(self, didLoad: data)
            }
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override public func stopLoading() {}

    /// Tiện ích tạo URLSessionConfiguration đã đăng ký MockURLProtocol
    public static func makeMockSessionConfiguration() -> URLSessionConfiguration {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return configuration
    }
}
