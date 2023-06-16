const rock: felt252 = 1;
const paper: felt252 = 2;
const scissors: felt252 = 3;

#[system]
mod CreateGame {
    use array::ArrayTrait;
    use traits::Into;

    use zkRPS::components::Game;

    fn execute(ctx: Context, rounds: u8) -> felt252 {
        let game_id = commands::uuid();

        commands::set_entity(
            game_id.into(),
            (Game {
                player: ctx.caller_account.into(),
                challenger: 0,
                rounds: rounds,
                winner: 0,
                player_wins: 0,
                challenger_wins: 0
            })
        )
        game_id.into()
    }
}

#[system]
mod JoinGame {
    use array::ArrayTrait;
    use traits::Into;

    use zkRPS::components::Game;

    fn execute(ctx: Context, game_id: felt252) {
        let game_sk: Query = game_id.into();

        let game = commands::<Game>::entity(game_sk);

        let challenger: felt252 = ctx.caller_account.into();

        // can only join game that has opening
        assert(game.challenger == 0, 'already matched');

        // remove after testing
        // assert(game.player != challenger, 'cannot play against self');

        // set game with challenger
        commands::set_entity(
            game_id.into(),
            (Game {
                player: game.player,
                challenger: challenger,
                rounds: game.rounds,
                winner: 0,
                player_wins: 0,
                challenger_wins: 0
            })
        )
    }
}

#[system]
mod Commit {
    use array::ArrayTrait;
    use traits::Into;

    use zkRPS::components::{Game, Turn};

    fn execute(ctx: Context, game_id: felt252, commit_hash: felt252) {
        let game_sk: Query = game_id.into();
        let game = commands::<Game>::entity(game_sk);

        let player = ctx.caller_account.into();

        let maybe_turn = commands::<Turn>::try_entity(game_sk);

        let player_move = match maybe_turn {
            Option::Some(turn) => turn.player_move.into(),
            Option::None(_) => 0,
        };

        let challenger_move = match maybe_turn {
            Option::Some(turn) => turn.challenger_move.into(),
            Option::None(_) => 0,
        };

        // if caller is player, set player move
        if (game.player == player) {
            // assert(player_move == 0, 'already committed');
            commands::set_entity(
                game_id.into(), (Turn { player_move: commit_hash, challenger_move })
            )
        // if caller is challenger, set challenger move
        } else {
            // assert(challenger_move == 0, 'already committed');
            commands::set_entity(
                game_id.into(), (Turn { player_move, challenger_move: commit_hash })
            )
        }
    }
}
#[system]
mod Reveal {
    use array::ArrayTrait;
    use serde::Serde;
    use traits::Into;
    use poseidon::poseidon_hash_span;


    use zkRPS::components::{Game, Turn};

    fn execute(ctx: Context, game_id: felt252, secret: felt252, move: felt252) {
        //
        // TODO: check valid move
        //
        let game_sk: Query = game_id.into();
        let game = commands::<Game>::entity(game_sk);

        let player: felt252 = ctx.caller_account.into();

        let current_turn = commands::<Turn>::entity(game_sk);

        // check current_turn is committed with both parties

        let maybe_turn = commands::<Turn>::try_entity(game_sk);
        // assert(maybe_turn.player_move != 0, 'no turn committed');
        // assert(maybe_turn.challenger_move != 0, 'no turn committed');

        // hash move
        let mut serialized = ArrayTrait::new();
        serialized.append(secret);
        serialized.append(move);

        let hash = poseidon_hash_span(serialized.span());

        // if caller is player, reveal
        if (game.player == player) {
            assert(hash.into() == current_turn.player_move, 'invalid move');
            commands::set_entity(
                game_id.into(),
                (Turn { player_move: move, challenger_move: current_turn.challenger_move.into() })
            )
        // if caller is challenger, reveal
        } else {
            assert(hash.into() == current_turn.challenger_move, 'invalid move');
            commands::set_entity(
                game_id.into(),
                (Turn { player_move: current_turn.player_move.into(), challenger_move: move })
            )
        }
    }
}
#[system]
mod Resolve {
    use array::ArrayTrait;
    use traits::{TryInto, Into};

    use zkRPS::components::{Game, Turn};

    fn execute(ctx: Context, game_id: felt252) {
        let game_sk: Query = game_id.into();
        let game = commands::<Game>::entity(game_sk);

        let player: felt252 = ctx.caller_account.into();

        let current_turn = commands::<Turn>::entity(game_sk);

        let player_move: u8 = current_turn.player_move.try_into().unwrap();
        let challenger_move: u8 = current_turn.challenger_move.try_into().unwrap();
        let result = (player_move - challenger_move) % 3;

        if (result < 0) {
            commands::set_entity(
                game_id.into(),
                (Game {
                    player: game.player,
                    challenger: game.challenger,
                    rounds: game.rounds,
                    winner: 0,
                    player_wins: game.player_wins,
                    challenger_wins: game.player_wins + 1
                })
            )
        } else if (result == 0) {
            commands::set_entity(
                game_id.into(),
                (Game {
                    player: game.player,
                    challenger: game.challenger,
                    rounds: game.rounds,
                    winner: 0,
                    player_wins: game.player_wins,
                    challenger_wins: game.player_wins
                })
            )
        } else {
            commands::set_entity(
                game_id.into(),
                (Game {
                    player: game.player,
                    challenger: game.challenger,
                    rounds: game.rounds,
                    winner: 0,
                    player_wins: game.player_wins + 1,
                    challenger_wins: game.player_wins
                })
            )
        }
    }
}

