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
        HStack(spacing: 8) {
            scoreCell(.one)
            VStack(spacing: 4) {
                Text("R\(state.round)")
                    .font(.caption.bold())
                    .foregroundStyle(SpearheadTheme.gold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(SpearheadTheme.gold.opacity(0.15), in: Capsule())
                Text("vs")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                if let underdog = state.underdog {
                    Image(systemName: "tortoise.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
            .frame(width: 36)
            scoreCell(.two)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private func scoreCell(_ side: PlayerSide) -> some View {
        let p = state[side]
        let isActive = state.activePlayer == side && state.stage != .startOfRound
        let color = side.themeColor
        return VStack(spacing: 3) {
            HStack(spacing: 4) {
                if isActive {
                    Image(systemName: "arrowtriangle.right.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(color)
                }
                Text(p.name)
                    .font(.caption.weight(isActive ? .bold : .regular))
                    .lineLimit(1)
            }
            Text("\(p.totalVP)")
                .font(.system(size: 34, weight: .heavy, design: .rounded).monospacedDigit())
                .foregroundStyle(isActive ? color : color.opacity(0.7))
            Text("VP")
                .font(.caption2.bold())
                .foregroundStyle(color.opacity(0.7))
                .offset(y: -6)
            HStack(spacing: 8) {
                Label("\(p.handCount)", systemImage: "rectangle.stack")
                Label("\(p.scoredTacticCount)", systemImage: "checkmark.seal")
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .padding(.horizontal, 8)
        .background(
            isActive
                ? AnyShapeStyle(color.opacity(0.15))
                : AnyShapeStyle(Color.clear),
            in: RoundedRectangle(cornerRadius: 12)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(isActive ? color.opacity(0.6) : color.opacity(0.15), lineWidth: 1.5)
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
