import Foundation
import CoreData

/// Service for managing game records and history
class GameRecordService {
    static let shared = GameRecordService()
    private let persistenceController = PersistenceController.shared

    private init() {}

    /// Save a completed game to Core Data
    func saveGame(
        gameState: GameStateManager,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let context = persistenceController.container.viewContext

        context.perform {
            do {
                let gameRecord = GameRecord(context: context)
                gameRecord.id = gameState.gameRecordId ?? UUID()
                gameRecord.date = Date()
                gameRecord.season = gameState.season
                gameRecord.boardLayout = gameState.boardLayout

                // Player setup
                if let mySetup = gameState.mySetup {
                    gameRecord.myArmyName = mySetup.armyName
                    gameRecord.mySpearheadName = mySetup.spearheadName
                    gameRecord.myFinalScore = Int16(mySetup.score)
                }

                if let opponentSetup = gameState.opponentSetup {
                    gameRecord.opponentArmyName = opponentSetup.armyName
                    gameRecord.opponentSpearheadName = opponentSetup.spearheadName
                    gameRecord.opponentFinalScore = Int16(opponentSetup.score)
                }

                // Determine winner
                let myScore = gameState.getMyScore()
                let opponentScore = gameState.getOpponentScore()
                gameRecord.didIWin = myScore > opponentScore
                gameRecord.isComplete = true

                // Save round records
                for roundData in gameState.roundRecords {
                    let roundRecord = RoundRecord(context: context)
                    roundRecord.id = UUID()
                    roundRecord.roundNumber = Int16(roundData.roundNumber)
                    roundRecord.whoWonPriority = roundData.whoWonPriority?.rawValue ?? ""
                    roundRecord.whoWentFirst = roundData.whoWentFirst?.rawValue ?? ""
                    roundRecord.underdogAtStart = roundData.underdogAtStart.rawValue
                    roundRecord.myScoreThisRound = Int16(roundData.myScoreThisRound)
                    roundRecord.opponentScoreThisRound = Int16(roundData.opponentScoreThisRound)
                    roundRecord.game = gameRecord
                }

                try context.save()
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }

    /// Fetch all game records, sorted by date (most recent first)
    func fetchAllGames() -> [GameRecord] {
        let context = persistenceController.container.viewContext
        let fetchRequest: NSFetchRequest<GameRecord> = GameRecord.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \GameRecord.date, ascending: false)]

        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Error fetching games: \(error)")
            return []
        }
    }

    /// Get win/loss statistics
    func getStatistics() -> (wins: Int, losses: Int, draws: Int, totalGames: Int) {
        let games = fetchAllGames()
        let totalGames = games.count

        var wins = 0
        var losses = 0
        var draws = 0

        for game in games {
            if game.myFinalScore == game.opponentFinalScore {
                draws += 1
            } else if game.didIWin {
                wins += 1
            } else {
                losses += 1
            }
        }

        return (wins, losses, draws, totalGames)
    }

    /// Delete a game record
    func deleteGame(_ game: GameRecord, completion: @escaping (Result<Void, Error>) -> Void) {
        let context = persistenceController.container.viewContext

        context.perform {
            do {
                context.delete(game)
                try context.save()
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }
}
