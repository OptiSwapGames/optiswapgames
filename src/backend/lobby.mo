import Array "mo:base/Array";
import Hash "mo:base/Hash";
import M "mo:base/HashMap";
import Principal "mo:base/Principal";
import Nat "mo:base/Nat";
import Int "mo:base/Int";
import Text "mo:base/Text";
import T "lobby-types";
import GameRouter "canister:bulldogblast";

actor class Lobby() = this {
    var balances = M.HashMap<Principal, Nat>(10, Principal.equal, Principal.hash);
    var queue : T.GameQueue = [];
    var entryFee = 10000000;

    public func gameStatus(id : Nat) : async T.GameStatus {
        return await GameRouter.gameStatus(id);
    };

    public func getQueue() : async T.GameQueue {
        return queue;
    };

    public shared(msg) func deposit() : async Nat { 
        return await updateTokenBalance(msg.caller, 100000000);
    };

    private func updateTokenBalance(user : Principal, delta : Int) : async Nat {
        var newAmount : Int = 0;
        var userBalances = M.HashMap<Principal, Nat>(10, Principal.equal, Principal.hash);
        switch (balances.get(user)) {
            case (?_userTokenBalance) {
                newAmount := _userTokenBalance + delta;
            };
            case _ {
                newAmount := delta;
            };
        };
        let newBalance : Nat = Int.abs(newAmount);
        balances.put(user, newBalance);
        return newBalance;
    };

    public shared(msg) func joinQueue(playerName: Text) : async T.QueueJoinResult {
        let proposedQueueEntry : T.QueueEntry = {
            player = msg.caller;
            amount = entryFee;
            name = playerName;
        };
        let array2 = [proposedQueueEntry];
        let proposedQueue = Array.append<T.QueueEntry>(queue, array2);

        let result : T.QueueJoinResult = await GameRouter.validateQueue(proposedQueue);
        switch (result.validity) {
            case (#Invalid) {
                //error
            };
            case (#ValidNotReady) {
                queue := proposedQueue
            };
            case (#ValidReady) {
                let newGame = await startGame(proposedQueue);
                queue := [];
            };
        };
        return {
          playerID = result.playerID;
          gameID = result.gameID;
          validity = result.validity;
        };
    };

    private func startGame(queue: [T.QueueEntry]) : async Text {
        for (i in queue.keys()) {
          let queueEntry = queue[i];
          let newBalance = await updateTokenBalance(queueEntry.player, -queueEntry.amount);
        };
        let newGame = await GameRouter.startGame(queue);
        return "";
    };

};
