use traits::Into;
use core::result::ResultTrait;
use array::{ArrayTrait, SpanTrait};
use option::OptionTrait;
use traits::TryInto;
use box::BoxTrait;
use clone::Clone;
use debug::PrintTrait;
use poseidon::poseidon_hash_span;
use serde::Serde;
use starknet::{ContractAddress, syscalls::deploy_syscall};
use starknet::class_hash::{ClassHash, Felt252TryIntoClassHash};
use dojo_core::storage::query::{IntoPartitioned, IntoPartitionedQuery};
use dojo_core::interfaces::{
    IWorldDispatcher, IWorldDispatcherTrait, IComponentLibraryDispatcher, IComponentDispatcherTrait,
    ISystemLibraryDispatcher, ISystemDispatcherTrait
};

use dojo_core::executor::Executor;
use dojo_core::world::World;
use dojo_core::test_utils::spawn_test_world;
use dojo_core::auth::systems::{Route, RouteTrait, GrantAuthRole};

use zkRPS::components::{Game, GameComponent, Turn, TurnComponent};
use zkRPS::systems::{CreateGame, JoinGame, Commit, Reveal};

const ROUNDS: u8 = 3;

fn spawn_game() -> (ContractAddress, felt252) {
    // components
    let mut components = array::ArrayTrait::new();
    components.append(GameComponent::TEST_CLASS_HASH);
    components.append(TurnComponent::TEST_CLASS_HASH);

    // systems
    let mut systems = array::ArrayTrait::new();
    systems.append(CreateGame::TEST_CLASS_HASH);
    systems.append(JoinGame::TEST_CLASS_HASH);
    systems.append(Commit::TEST_CLASS_HASH);
    systems.append(Reveal::TEST_CLASS_HASH);
    // systems.append(Resolve::TEST_CLASS_HASH);

    // auth routes
    let mut routes = array::ArrayTrait::new();
    routes.append(RouteTrait::new('CreateGame'.into(), 'GameWriter'.into(), 'Game'.into()));
    routes.append(RouteTrait::new('JoinGame'.into(), 'GameWriter'.into(), 'Game'.into()));
    routes.append(RouteTrait::new('Commit'.into(), 'GameWriter'.into(), 'Game'.into()));

    routes.append(RouteTrait::new('Commit'.into(), 'GameWriter'.into(), 'Turn'.into()));
    routes.append(RouteTrait::new('Reveal'.into(), 'GameReader'.into(), 'Turn'.into()));
    routes.append(RouteTrait::new('Resolve'.into(), 'GameReader'.into(), 'Turn'.into()));

    let world = spawn_test_world(components, systems, routes);

    let mut spawn_game_calldata = array::ArrayTrait::<felt252>::new();
    spawn_game_calldata.append(ROUNDS.into());

    let mut res = world.execute('CreateGame'.into(), spawn_game_calldata.span());
    assert(res.len() > 0, 'did not create game');

    let game_id = serde::Serde::<felt252>::deserialize(ref res)
        .expect('spawn deserialization failed');

    (world.contract_address, game_id)
}

#[test]
#[available_gas(100000000)]
fn test_spawn_game() {
    let (world_address, game_id) = spawn_game(); //creator auto joins
    let (games, _) = IWorldDispatcher {
        contract_address: world_address
    }.entities('Game'.into(), game_id.into());
    assert(games.len() == 1, 'wrong num games');
}
#[test]
#[available_gas(100000000)]
fn test_join_game() {
    let (world_address, game_id) = spawn_game(); //creator auto joins
    let world = IWorldDispatcher { contract_address: world_address };

    let mut spawn_location_calldata = array::ArrayTrait::<felt252>::new();
    spawn_location_calldata.append(game_id);

    let mut res = world.execute('JoinGame'.into(), spawn_location_calldata.span());

    let mut joined = IWorldDispatcher {
        contract_address: world_address
    }.entity('Game'.into(), game_id.into(), 0, 0);

    // check game
    let current_game = serde::Serde::<Game>::deserialize(ref joined)
        .expect('loc deserialization failed');
    assert(current_game.rounds == ROUNDS, 'wrong num rounds');
    assert(current_game.player == game_id, 'wrong player1');
    assert(current_game.challenger == game_id, 'wrong player2');

    // hashed p1 move
    let mut serialized = ArrayTrait::new();
    'secret'.serialize(ref serialized); // secret
    'Rock'.serialize(ref serialized); // move
    let hash = poseidon_hash_span(serialized.span());

    // commit
    let mut spawn_location_calldata = array::ArrayTrait::<felt252>::new();
    spawn_location_calldata.append(game_id);
    spawn_location_calldata.append(hash);

    let mut res = world.execute('Commit'.into(), spawn_location_calldata.span());
// hashed p2 move
// let mut serialized = ArrayTrait::new();
// 'secret'.serialize(ref serialized); // secret
// 'scissors'.serialize(ref serialized); // move
// let hash = poseidon_hash_span(serialized.span());

// // commit
// let mut spawn_location_calldata = array::ArrayTrait::<felt252>::new();
// spawn_location_calldata.append(game_id);
// spawn_location_calldata.append(hash);

// let mut res = world.execute('Commit'.into(), spawn_location_calldata.span());
}

