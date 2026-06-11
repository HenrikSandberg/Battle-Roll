import SwiftUI

/// The main in-battle screen: scoreboard, phase bar, phase content, turn controls.
struct BattleView: View {
    @ObservedObject var session: BattleSession
    @EnvironmentObject private var sessionStore: SessionStore
    let onExit: () -> Void

    @State private var showScoring = false
    @State private var showUnits = false
    @State private var showTactics = false
    @State private var showQuitConfirm = false
    @State private var tacticsSide: PlayerSide = .one

    private var state: BattleState { session.state }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                scoreboard
                if let twist = session.currentTwist {
                    TwistBanner(twist: twist, realmID: session.realm.id)
                }
                PhaseBar(phase: state.phase)
                Divider()
                PhaseContentView(session: session,
                                 showUnits: $showUnits,
                                 showTactics: openTactics)
                Divider()
                turnControls
            }
            .navigationTitle("Round \(state.round) of 4")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showQuitConfirm = true
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showUnits = true
                    } label: {
                        Image(systemName: "person.3")
                    }
                }
            }
            .sheet(isPresented: $showScoring) {
                EndOfTurnScoringSheet(session: session)
            }
            .sheet(isPresented: $showUnits) {
                UnitTrackerView(session: session)
            }
            .sheet(isPresented: $showTactics) {
                TacticHandView(session: session, side: tacticsSide)
            }
            .overlay {
                if state.stage == .startOfRound && !state.isOver {
                    StartOfRoundView(session: session, showTactics: openTactics)
                }
                if state.isOver {
                    GameOverView(session: session) {
                        sessionStore.finishGame(session)
                        onExit()
                    }
                }
            }
            .confirmationDialog("Leave battle?", isPresented: $showQuitConfirm) {
                Button("Save and close") { onExit() }
                Button("Abandon battle", role: .destructive) {
                    sessionStore.clearCurrent()
                    onExit()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Save and close keeps the battle so you can resume it later.")
            }
        }
    }

    private func openTactics(_ side: PlayerSide) {
        tacticsSide = side
        showTactics = true
    }

    private var scoreboard: some View {
        HStack(spacing: 12) {
            scoreCell(.one)
            VStack(spacing: 2) {
                Text(state.activePlayer == .one ? "◀ turn" : "turn ▶")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                if let underdog = state.underdog {
                    Label(state[underdog].name, systemImage: "tortoise")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                        .labelStyle(.titleAndIcon)
                }
            }
            scoreCell(.two)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private func scoreCell(_ side: PlayerSide) -> some View {
        let p = state[side]
        let isActive = state.activePlayer == side && state.stage != .startOfRound
        let color = side.themeColor
        return VStack(spacing: 2) {
            Text(p.name)
                .font(.subheadline.weight(isActive ? .bold : .regular))
                .lineLimit(1)
            Text("\(p.totalVP) VP")
                .font(.title2.bold().monospacedDigit())
                .foregroundStyle(color)
            Text("Hand: \(p.handCount) · Tactics: \(p.scoredTacticCount)")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(color.opacity(isActive ? 0.18 : 0.06),
                    in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(isActive ? color : Color.clear, lineWidth: 1.5)
        )
    }

    private var turnControls: some View {
        HStack {
            Button {
                session.retreatPhase()
            } label: {
                Image(systemName: "chevron.left")
                    .frame(width: 44, height: 44)
            }
            .disabled(state.phase == .startOfTurn)

            Spacer()

            if state.phase == .endOfTurn {
                Button {
                    showScoring = true
                } label: {
                    Label("Score & End Turn", systemImage: "flag.checkered")
                        .font(.headline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(SpearheadTheme.fireGradient, in: Capsule())
                        .foregroundStyle(.white)
                }
            } else {
                Button {
                    session.advancePhase()
                } label: {
                    Label("Next Phase", systemImage: "chevron.right")
                        .font(.headline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(state.phase.themeColor.opacity(0.15), in: Capsule())
                        .foregroundStyle(state.phase.themeColor)
                }
            }

            Spacer()

            Button {
                session.advancePhase()
            } label: {
                Image(systemName: "chevron.right")
                    .frame(width: 44, height: 44)
            }
            .disabled(state.phase == .endOfTurn)
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
    }
}

/// Horizontal selector of the 7 turn steps.
struct PhaseBar: View {
    let phase: GamePhase

    var body: some View {
        HStack(spacing: 4) {
            ForEach(GamePhase.allCases) { p in
                VStack(spacing: 3) {
                    Image(systemName: p.symbolName)
                        .font(.system(size: 14, weight: p == phase ? .bold : .regular))
                        .foregroundStyle(p == phase ? Color.white : p.themeColor)
                    Text(p.shortName)
                        .font(.system(size: 9, weight: p == phase ? .bold : .regular))
                        .foregroundStyle(p == phase ? Color.white : Color.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(p == phase ? p.themeColor : Color.clear,
                            in: RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }
}

struct TwistBanner: View {
    let twist: TwistCard
    let realmID: String
    @State private var expanded = false

    var body: some View {
        Button {
            withAnimation { expanded.toggle() }
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Label("Twist: \(twist.name)", systemImage: "tornado")
                        .font(.subheadline.bold())
                    Spacer()
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                }
                if expanded {
                    Text(twist.effect)
                        .font(.caption)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(.white)
            .background(SpearheadTheme.realmGradient(realmID))
        }
        .buttonStyle(.plain)
    }
}
