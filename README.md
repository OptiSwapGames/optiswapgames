# Bulldog Blast

Bulldog Blast is a proof-of-concept semi-realtime multiplayer arcade combat game.
It runs entirely on the Internet Computer. The components are structured to work within a flexible, token-integrated architecture. 
The following is a typical workflow:
```mermaid
sequenceDiagram
    participant User
    participant Lobby
    participant GameRouter
    participant Game
    User-->>Lobby: Deposit Tokens
    User->>Lobby: Join Queue, Commit Tokens
    Lobby->>GameRouter: Validate Queue
    GameRouter->>Game: Start Game
    loop GameInstance
        Game->>Game: 
        User->>GameRouter: Turn Input
        GameRouter->>Game: Input Routing
        Game->>GameRouter: Game View
        GameRouter->>User: Game View
    end
    Game->>GameRouter: Report Status
    GameRouter-->>Lobby: Settle Tokens
    Lobby-->>User: Withdraw Tokens
```

The dotted lines are pending future work on ERC-20 integration.

```
nix-shell
sh start.sh
dfx deploy
```
