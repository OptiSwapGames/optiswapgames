import M "mo:base/HashMap";

module {

  public type GameStatus = {
    #Nonexistent;
    #Active;
    #Complete;
    #Finalized;
  };

  public type GameInterface = actor {
    gameStatus: (Nat) -> async GameStatus;
    validateQueue : ([QueueEntry]) -> async QueueJoinResult;
    startGame : ([QueueEntry]) -> async Nat;
  };

  public type GameQueue = [QueueEntry];

  public type QueueEntry = {
    player : Principal;
    amount : Nat;
    name : Text;
  };

  public type QueueValidation = {
    #ValidNotReady;
    #ValidReady;
    #Invalid;
  };

  public type QueueJoinResult = {
    gameID : Nat;
    playerID: Nat;
    validity : QueueValidation;
  };

}
