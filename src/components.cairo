use array::ArrayTrait;


#[derive(Component, Copy, Drop, Serde)]
struct Game {
    player: felt252,
    challenger: felt252,
    rounds: u8,
    winner: u8,
    player_wins: u8,
    challenger_wins: u8
}

#[derive(Component, Copy, Drop, Serde)]
struct Turn {
    player_move: felt252,
    challenger_move: felt252
}
