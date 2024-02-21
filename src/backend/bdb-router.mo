import M "mo:base/HashMap";
import Nat "mo:base/Nat";
import Hash "mo:base/Hash";
import Principal "mo:base/Principal";
import List "mo:base/List";
import G "bdb-types";
import L "lobby-types";
import Game "bdb-game";

actor class GameRouter() = this {

  var mostRecentSession = 0;
  var gameSessions = M.HashMap<Nat, Game.Game>(10, Nat.equal, Hash.hash);

  public func startGame(queue: [L.QueueEntry]) : async Nat {
    mostRecentSession := mostRecentSession + 1;
    let game = Game.Game(queue);
    gameSessions.put(mostRecentSession, game);

    return mostRecentSession;
  };

  public func getScores(gameID : Nat) : async [L.QueueEntry] {
    switch (gameSessions.get(gameID)) {
        case (?game) { 
            return (await game.getScores());
        };
        case (null) {
            return ([]);
        };
    };
  };

  public func validateQueue(queue: [L.QueueEntry]) : async L.QueueJoinResult {
    var isValid = false;
    var isReady = false;
    var totalPlayers = 0;
    for (i in queue.keys()) {
      let queueEntry = queue[i];
      if (queueEntry.amount != 10000000) {
        return {
            validity = #Invalid;
            gameID = 0;
            playerID = 0;
        };
      };
      totalPlayers := totalPlayers + 1;
    };
    if (totalPlayers > 4) {
      return {
          validity = #Invalid;
          gameID = 0;
          playerID = 0;
      };
    };
    if (totalPlayers == 4) {
      return {
          validity = #ValidReady;
          gameID = mostRecentSession + 1;
          playerID = totalPlayers;
      };
    };
    return {
        validity = #ValidNotReady;
        gameID = mostRecentSession + 1;
        playerID = totalPlayers;
    };
  };

  public func gameStatus(gameID : Nat) : async L.GameStatus {
    switch (gameSessions.get(gameID)) {
        case (?game) {
            return await game.status();
        };
        case (null) {
            return #Nonexistent;
        };
    };
  };

  public func getGameView(gameID : Nat) : async G.BDBView {
    switch (gameSessions.get(gameID)) {
        case (?game) {
            return await game.getGameView();
        };
        case (null) {
            
            let result : G.BDBView = {
                status = #Nonexistent;
                objects = [];
                dataKeys = [];
                dataValues = [];
                tick = 0;
            };
              return result;
        };
    };
  };

  public shared func getTick(gameID: Nat) : async Nat {
    switch (gameSessions.get(gameID)) {
        case (?game) {
             return await game.getTick()
        };
        case (null) {return 0};
    };
  };

  public shared(msg) func input(gameID: Nat, playerID: Nat, command: G.InputCommand) : async G.Result {
    switch (gameSessions.get(gameID)) {
        case (?game) {
             return await game.processInputCommand(playerID, command);
        };
        case (null) {
           return #Err;
        };
    }
  };

};

