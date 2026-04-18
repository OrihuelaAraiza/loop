//
//  loopTests.swift
//  loopTests
//
//  Created by Juan Pablo Orihuela Araiza on 15/04/26.
//

import Testing
@testable import loop

@MainActor
struct loopTests {

    @Test func placementStepIsInsertedOnlyWhenEnabled() async throws {
        let viewModel = OnboardingViewModel()

        #expect(viewModel.totalSteps == 7)
        #expect(!viewModel.steps.contains(.placement))

        viewModel.setPlacementTestEnabled(true)

        #expect(viewModel.totalSteps == 8)
        #expect(viewModel.steps.contains(.placement))
        #expect(viewModel.steps[5] == .placement)
    }

    @Test func placementResultUpdatesKnowledgeLevelFromAnswers() async throws {
        let viewModel = OnboardingViewModel()
        viewModel.setPlacementTestEnabled(true)

        let questions = viewModel.placementQuestions
        let firstQuestion = try #require(questions.first)
        let secondQuestion = try #require(questions.dropFirst().first)
        let thirdQuestion = try #require(questions.dropFirst(2).first)

        viewModel.answerPlacementQuestion(firstQuestion.id, with: firstQuestion.correctOptionID)
        viewModel.answerPlacementQuestion(secondQuestion.id, with: secondQuestion.correctOptionID)
        viewModel.answerPlacementQuestion(thirdQuestion.id, with: "a")

        viewModel.completePlacementTest()

        #expect(viewModel.placementScore == 2)
        #expect(viewModel.userProfile.knowledgeLevel == .basicKnows)
    }

    @Test func disablingPlacementClearsProgress() async throws {
        let viewModel = OnboardingViewModel()
        viewModel.setPlacementTestEnabled(true)

        let firstQuestion = try #require(viewModel.placementQuestions.first)
        viewModel.answerPlacementQuestion(firstQuestion.id, with: firstQuestion.correctOptionID)
        viewModel.completePlacementTest()

        viewModel.setPlacementTestEnabled(false)

        #expect(viewModel.placementScore == 0)
        #expect(viewModel.placementAnswers.isEmpty)
        #expect(viewModel.totalSteps == 7)
    }

}
