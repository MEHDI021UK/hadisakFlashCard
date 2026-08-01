//
//  hadisakTests.swift
//  hadisakTests
//

import XCTest
@testable import hadisak

final class SM2SchedulerTests: XCTestCase {
    private var scheduler: SM2Scheduler!

    override func setUp() {
        super.setUp()
        scheduler = SM2Scheduler(configuration: .default)
    }

    func testNewCardAgainStaysInLearning() {
        let result = scheduler.schedule(
            status: .new,
            easeFactor: 2.5,
            interval: 0,
            repetitions: 0,
            lapses: 0,
            learningStep: 0,
            rating: .again
        )
        XCTAssertEqual(result.status, .learning)
        XCTAssertEqual(result.learningStep, 0)
        XCTAssertLessThan(result.interval, 1)
    }

    func testLearningGoodAdvancesStep() {
        let result = scheduler.schedule(
            status: .learning,
            easeFactor: 2.5,
            interval: 1.0 / (24 * 60),
            repetitions: 0,
            lapses: 0,
            learningStep: 0,
            rating: .good
        )
        XCTAssertEqual(result.status, .learning)
        XCTAssertEqual(result.learningStep, 1)
    }

    func testLearningGoodGraduates() {
        let result = scheduler.schedule(
            status: .learning,
            easeFactor: 2.5,
            interval: 10.0 / (24 * 60),
            repetitions: 0,
            lapses: 0,
            learningStep: 1,
            rating: .good
        )
        XCTAssertEqual(result.status, .review)
        XCTAssertEqual(result.interval, 1, accuracy: 0.001)
    }

    func testLearningEasyGraduatesWithLongerInterval() {
        let result = scheduler.schedule(
            status: .learning,
            easeFactor: 2.5,
            interval: 0,
            repetitions: 0,
            lapses: 0,
            learningStep: 0,
            rating: .easy
        )
        XCTAssertEqual(result.status, .review)
        XCTAssertEqual(result.interval, 4, accuracy: 0.001)
    }

    func testReviewAgainBecomesRelearning() {
        let result = scheduler.schedule(
            status: .review,
            easeFactor: 2.5,
            interval: 10,
            repetitions: 3,
            lapses: 0,
            learningStep: 0,
            rating: .again
        )
        XCTAssertEqual(result.status, .relearning)
        XCTAssertEqual(result.lapses, 1)
        XCTAssertEqual(result.repetitions, 0)
        XCTAssertLessThan(result.easeFactor, 2.5)
    }

    func testReviewGoodIncreasesInterval() {
        let result = scheduler.schedule(
            status: .review,
            easeFactor: 2.5,
            interval: 4,
            repetitions: 2,
            lapses: 0,
            learningStep: 0,
            rating: .good
        )
        XCTAssertEqual(result.status, .review)
        XCTAssertEqual(result.interval, 10, accuracy: 0.001)
        XCTAssertEqual(result.repetitions, 3)
    }

    func testReviewEasyBoostsEase() {
        let result = scheduler.schedule(
            status: .review,
            easeFactor: 2.5,
            interval: 4,
            repetitions: 2,
            lapses: 0,
            learningStep: 0,
            rating: .easy
        )
        XCTAssertEqual(result.status, .review)
        XCTAssertEqual(result.easeFactor, 2.65, accuracy: 0.001)
        XCTAssertGreaterThan(result.interval, 4)
    }

    func testPreviewContainsAllRatings() {
        let previews = scheduler.previewIntervals(
            status: .review,
            easeFactor: 2.5,
            interval: 3,
            repetitions: 2,
            lapses: 0,
            learningStep: 0
        )
        XCTAssertEqual(previews.count, 4)
        XCTAssertNotNil(previews[.again])
        XCTAssertNotNil(previews[.hard])
        XCTAssertNotNil(previews[.good])
        XCTAssertNotNil(previews[.easy])
    }
}

final class TextDirectionDetectorTests: XCTestCase {
    func testEnglishIsLTR() {
        XCTAssertEqual(TextDirectionDetector.detect(in: "Hello world"), .leftToRight)
    }

    func testPersianIsRTL() {
        XCTAssertEqual(TextDirectionDetector.detect(in: "سلام دنیا"), .rightToLeft)
    }

    func testArabicIsRTL() {
        XCTAssertEqual(TextDirectionDetector.detect(in: "مرحبا"), .rightToLeft)
    }

    func testHebrewIsRTL() {
        XCTAssertEqual(TextDirectionDetector.detect(in: "שלום"), .rightToLeft)
    }

    func testMixedPrefersMajority() {
        let mostlyPersian = TextDirectionDetector.detect(in: "سلام دنیا و دوستان عزیز hello")
        XCTAssertEqual(mostlyPersian, .rightToLeft)

        let mostlyEnglish = TextDirectionDetector.detect(in: "Hello world and friends سلام")
        XCTAssertEqual(mostlyEnglish, .leftToRight)
    }
}

final class ImportServiceTests: XCTestCase {
    private let service = ImportService()

    func testParseTXT() throws {
        let simple = """
        Cat
        گربه
        ---
        Dog
        سگ
        animals
        """
        let data = Data(simple.utf8)
        let pairs = try service.parseTXT(data)
        XCTAssertEqual(pairs.count, 2)
        XCTAssertEqual(pairs[0].front, "Cat")
        XCTAssertEqual(pairs[0].back, "گربه")
        XCTAssertEqual(pairs[1].tags, ["animals"])
    }

    func testParseCSV() throws {
        let csv = """
        front,back,tags
        Hello,سلام,"greeting, fa"
        World,دنیا,noun
        """
        let pairs = try service.parseCSV(Data(csv.utf8))
        XCTAssertEqual(pairs.count, 2)
        XCTAssertEqual(pairs[0].front, "Hello")
        XCTAssertEqual(pairs[0].back, "سلام")
        XCTAssertEqual(pairs[0].tags, ["greeting", "fa"])
    }
}
