# zkRPS 🪨📜✂️

A simple rock-paper-scissors commit reveal scheme game built on dojo

### Install

To install Dojo, use the following commands:

1. Follow the instructions at [https://book.dojoengine.org/getting-started/installation.html](https://book.dojoengine.org/getting-started/installation.html) to install Dojo.

### Usage

Once Dojo is installed, follow these steps:

1. Run Katana: `katana --seed 0 --allow-zero-max-fee`
2. Build the game: `sozo build`
3. Deploy the game to Katana: `sozo migrate` (you will need to comment out the World address in Scarb.toml, then once deployed uncomment)
4. Create a game: `sozo execute CreateGame --calldata 3`
5. Open another terminal and navigate to the `player_two` directory
6. Join the game as player two: `sozo execute JoinGame --calldata 0`
7. In the original terminal, commit your Poseidon hash: `sozo execute Commit --calldata=0,214585235161475357424179868697593518496576949055548172335309505920954063106`
8. In the `player_two` terminal, commit your move: `sozo execute Commit --calldata=0,3165026789427940773000938179506358876317298524448703329726057549612803596036`
9. Reveal player 1's move: `sozo execute Reveal --calldata=0,12345,1`
10. Reveal player 2's move: `sozo execute Reveal --calldata=0,12345,2`

## The Game

Create a game with any number of `rounds`. Once a game is created a challenger can join. Once this happens the game can begin.

1. Each player submits a poseidon hash of their move along with a secret via the `Commit` system
2. Once both moves have been submitted, each player can reveal their move via the `Reveal` system, which checks the hash
3. Once revealed anyone can call the `Resolve` which will complete the round
