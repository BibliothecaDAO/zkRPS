# zkRPS 🪨📜✂️

A simple rock-paper-scissors commit reveal scheme game built on dojo

`sozo execute CreateGame --calldata 3`

`sozo execute JoinGame --calldata 0`

`sozo execute Commit --calldata=0,214585235161475357424179868697593518496576949055548172335309505920954063106`

`sozo execute Commit --calldata=0,3165026789427940773000938179506358876317298524448703329726057549612803596036`

`sozo execute Reveal --calldata=0,12345,1`

`sozo execute Reveal --calldata=0,12345,2`


## The Game

Create a game with any number of `rounds`. Once a game is created a challenger can join. Once this happens the game can begin.

1. Each player submits a poseidon hash of their move along with a secret via the `Commit` system
2. Once both moves have been submitted, each player can reveal their move via the `Reveal` system, which checks the hash
3. Once revealed anyone can call the `Resolve` which will complete the round
