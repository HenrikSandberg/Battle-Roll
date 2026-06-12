import SwiftUI

/// Full-screen overlay guiding the official start-of-round sequence:
/// 1. priority (round 1: attacker chooses) · 2. underdog · 3. twist · 4. tactic draws.
struct StartOfRoundView: View {
    @ObservedObject var session: BattleSession
    let showTactics: (PlayerSide) -> Void

    @State private var firstPlayer: PlayerSide?
    @State private var wonAfterGoingSecond = false
    @State private var twistName: String?

    private var state: BattleState { session.state }
    private var isFirstRound: Bool { state.round == 1 }

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Start of Round \(state.round)")
                        .font(.largeTitle.bold())
                        .frame(maxWidth: .infinity)

                    prioritySection

                    if state.round >= 2 {
                        underdogSection
                    }

                    twistSection

                    tacticSection

                    Button {
                        begin()
                    } label: {
                        Label("Begin Round \(state.round)", systemImage: "play.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(canBegin ? AnyShapeStyle(SpearheadTheme.fireGradient) : AnyShapeStyle(Color.gray),
                                        in: RoundedRectangle(cornerRadius: 12))
                            .foregroundStyle(.white)
                    }
                    .disabled(!canBegin)
                }
                .padding()
            }
        }
    }

    private var canBegin: Bool { firstPlayer != nil && twistName != nil }

    // MARK: - Sections

    private var prioritySection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                if isFirstRound {
                    Text("The attacker (\(state[state.attacker].name)) chooses who takes the first turn.")
                        .font(.callout)
                } else {
                    Text("Both players roll a D6. The winner chooses who goes first. On a tie, the player who went first last round (\(state[state.firstPlayerByRound[state.round - 1] ?? state.attacker].name)) chooses.")
                        .font(.callout)
                }
                Picker("First turn", selection: $firstPlayer) {
                    Text("—").tag(PlayerSide?.none)
                    Text(state[.one].name).tag(PlayerSide?.some(.one))
                    Text(state[.two].name).tag(PlayerSide?.some(.two))
                }
                .pickerStyle(.segmented)

                if state.round >= 2, let fp = firstPlayer,
                   fp == (state.firstPlayerByRound[state.round - 1] ?? state.attacker).other {
                    Toggle(isOn: $wonAfterGoingSecond) {
                        Text("\(state[fp].name) went second last round and won the priority roll (seizing the initiative)")
                            .font(.caption)
                    }
                    if wonAfterGoingSecond {
                        seizeWarning(for: fp)
                    }
                }
            }
        } label: {
            Label(isFirstRound ? "First turn" : "Priority roll", systemImage: "dice")
                .foregroundStyle(SpearheadTheme.gold)
        }
    }

    @ViewBuilder
    private func seizeWarning(for side: PlayerSide) -> some View {
        let trailing = state.trailingPlayer()
        let bigUnderdog = trailing == side && state.vpDifference() >= 5
        Label(bigUnderdog
              ? "\(state[side].name) is the underdog by 5+ VP, so they still draw battle tactic cards."
              : "Seizing the initiative: \(state[side].name) does not draw battle tactic cards this round.",
              systemImage: "exclamationmark.triangle.fill")
            .font(.caption)
            .foregroundStyle(.orange)
    }

    private var underdogSection: some View {
        GroupBox {
            let trailing = state.trailingPlayer()
            if let trailing {
                Label("\(state[trailing].name) is the underdog (\(state[trailing].totalVP) VP vs \(state[trailing.other].totalVP) VP).",
                      systemImage: "tortoise.fill")
                    .font(.callout)
            } else {
                Label("Scores are tied — no underdog this round.", systemImage: "equal.circle")
                    .font(.callout)
            }
        } label: {
            Label("Underdog", systemImage: "tortoise")
                .foregroundStyle(SpearheadTheme.flame)
        }
    }

    private var twistSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                Text("Draw one twist card from the \(session.realm.name) deck.")
                    .font(.callout)
                Menu {
                    ForEach(availableTwists) { twist in
                        Button(twist.name) { twistName = twist.name }
                    }
                } label: {
                    HStack {
                        Text(twistName ?? "Pick the drawn card…")
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down")
                    }
                    .padding(10)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
                }
                Button {
                    let drawn = Set(state.twistByRound.values)
                    twistName = session.realm.twists.filter { !drawn.contains($0.name) }.randomElement()?.name
                } label: {
                    Label("Let the app draw", systemImage: "shuffle")
                        .font(.caption)
                }
                if let twistName, let twist = session.realm.twists.first(where: { $0.name == twistName }) {
                    Text(twist.effect)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } label: {
            Label("Twist", systemImage: "tornado")
                .foregroundStyle(SpearheadTheme.arcane)
        }
    }

    private var availableTwists: [TwistCard] {
        let drawn = Set(state.twistByRound.values)
        return session.realm.twists.filter { !drawn.contains($0.name) }
    }

    private var tacticSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                Text(isFirstRound
                     ? "Each player draws a hand of 3 battle tactic cards. If you can't see your opponent's cards, track theirs as hidden cards."
                     : "Each player may discard any cards, then draws back up to 3.")
                    .font(.callout)
                ForEach(PlayerSide.allCases) { side in
                    Button {
                        showTactics(side)
                    } label: {
                        HStack {
                            Circle()
                                .fill(side.themeColor)
                                .frame(width: 10, height: 10)
                            Text("\(state[side].name): \(state[side].handCount)/3 in hand")
                            Spacer()
                            Image(systemName: "rectangle.stack")
                        }
                        .padding(10)
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        } label: {
            Label("Battle tactic cards", systemImage: "rectangle.stack")
                .foregroundStyle(SpearheadTheme.ember)
        }
    }

    private func begin() {
        guard let firstPlayer, let twistName else { return }
        session.drawTwist(twistName)
        session.beginRound(firstPlayer: firstPlayer,
                           wonPriorityAfterGoingSecond: wonAfterGoingSecond)
    }
}
