import Timer "mo:base/Timer";
import M "mo:base/HashMap";
import List "mo:base/List";
import Nat "mo:base/Nat";
import Text "mo:base/Text";
import Float "mo:base/Float";
import Int "mo:base/Int";
import Hash "mo:base/Hash";
import Iter "mo:base/Iter";
import Principal "mo:base/Principal";
import T "bdb-types";

module{
  public class Game(queue: [T.QueueEntry]) = {

    var gameStatus: T.GameStatus = #Active;
    var tick : Nat = 0;
    var timerID : Nat = 0;

    var principals = M.HashMap<Nat, Principal> (10, Nat.equal, Hash.hash);
    var ships = List.nil<T.GameObject>(); 
    var asteroids = List.nil<T.GameObject>();
    var bombs = List.nil<T.GameObject>();

    var fireIntents = List.nil<T.InputCommand>();
    var thrustIntents = List.nil<T.InputCommand>();

    var natData = M.HashMap<Text, Nat> (10, Text.equal, Text.hash);
    var idcounter : Nat = 0;

    func datakey(id: Nat, lookup: Text): Text {
      return Text.concat(Nat.toText(id), lookup);
    };

    func makeid(): Nat {
      idcounter := idcounter + 1;
      return idcounter;
    };

    func getNat(go: T.GameObject, lookup: Text) : Nat {
      return getNatForID(go.id, lookup);
    };

    func getNatForID(id: Nat, lookup: Text) : Nat {
      let key = datakey(id, lookup);
      switch (natData.get(key)) {
        case (null) {
          return 0;
        };
        case (?nat) {
          return nat;
        };
      };
    };

    func setNat(go: T.GameObject, lookup: Text, nat: Nat) {
      setNatForID(go.id, lookup, nat);
    };

    func setNatForID(id: Nat, lookup: Text, nat: Nat) {
      let key = datakey(id, lookup);
      natData.put(datakey(id, lookup), nat);
    };

    func clearNat(go : T.GameObject, lookup: Text) {
      let key = datakey(go.id, lookup);
      let _ = natData.remove(key);
    };

    func makeGameObject(got : T.GameObjectType, pp : T.PhysicalPresence) : T.GameObject {
       let go: T.GameObject = {
         t = got;
         id = makeid();
         cleanup = false;
         physicalPresence = pp;
      };
      return go;
    };

    public func makeShip(x: Float, y: Float) : Nat  {
      let pp : T.PhysicalPresence = {
        inertialState = {
          position = { x = x; y = y};
          velocity = { x = 0; y = 0};
          acceleration = { x = 0; y = 0};
          mass = 10;
        };
        radius=3;
      };
      let ship = makeGameObject(#Ship, pp);
      ships := List.push<T.GameObject>(ship, ships);
      setNat(ship, ".ship.health", 100);
      setNat(ship, ".ship.score", 0);
      return ship.id;
    };

    func makeBomb(ship : T.GameObject, cmd : T.InputCommand) : Nat {
      let shipPos = ship.physicalPresence.inertialState.position;
      let d : Float = distance(shipPos, cmd.vector);
      let vx : Float = (cmd.vector.x - shipPos.x) / d;
      let vy : Float = (cmd.vector.y - shipPos.y) / d;
      let v : T.Vector = {
        x = vx;
        y = vy;
      };
      let pp = { radius = 1;
                  inertialState = {
                    mass = 1;
                    position = shipPos;
                    velocity = v;
                    acceleration = { x = 0.0; y = 0.0; };
                  }};
      let bomb = makeGameObject(#Bomb, pp);
      setNat(bomb, ".bomb.launchedBy", cmd.player);
      setNat(bomb, ".bomb.tick", 1);
      setNat(bomb, ".bomb.power", 100);
      setNat(bomb, ".bomb.blastRadius", 100);
      bombs := List.push<T.GameObject>(bomb, bombs);
      return bomb.id;
    };

    func launchBombs() : T.Result {
      var newBombs = List.nil<T.GameObject>(); 
      List.iterate<T.GameObject>(ships, func (go) {
        switch (List.find<T.InputCommand>(fireIntents, func cmd { cmd.player == go.id })) {
          case (null) { };
          case (?inputCommand) {
           let _ = makeBomb(go, inputCommand);
         };
        };
      });
      fireIntents := List.nil<T.InputCommand>();
     return #Ok;
    };

    func endGame() {
      gameStatus := #Complete;
      Timer.cancelTimer(timerID);
    };

    func checkGameOver() {
      var livingShips = 0;
      List.iterate<T.GameObject>(ships, func (go) {
        if (getNat(go, ".ship.health") > 0) {
          livingShips := livingShips + 1;
        }
      });
      if (livingShips <= 1) {
        endGame();
      };
    };

    func tickBombs() : T.Result {
      bombs := List.map<T.GameObject, T.GameObject>(bombs, func (go) {
        let bombTick = getNat(go, ".bomb.tick");
        if (bombTick == 0) {
          let r = getNat(go, ".bomb.blastRadius");
          List.iterate<T.GameObject>(ships, func (ship) {
            let dist : Int = Float.toInt(distance(go.physicalPresence.inertialState.position, ship.physicalPresence.inertialState.position));
            if (dist < r) {
              let damage = getNat(go, ".bomb.power") - dist;
              let shipHealth = getNat(ship, ".ship.health");
              let bombSource = getNat(go, ".bomb.launchedBy");
              setNatForID(bombSource, ".ship.score", Int.abs(getNatForID(bombSource, ".ship.score") + damage));
              if (damage >= shipHealth) {
                setNat(ship, ".ship.health", 0);
                checkGameOver();
              } else {
                setNat(ship, ".ship.health", Int.abs(shipHealth - damage));
              };
            }
          });
          clearNat(go, ".bomb.launchedBy");
          clearNat(go, ".bomb.tick");
          clearNat(go, ".bomb.power");
          clearNat(go, ".bomb.blastRadius");
          return ({go with 
            cleanup = true;
          });
        } else {
          setNat(go, ".bomb.tick", bombTick - 1);
          return go;
        };
      });
      return #Ok;
    };

    func mainLoop() : async T.Result {
      bombs := move(bombs);
      ships := move(ships);
      let _ = tickBombs();
      bombs := cleanup(bombs);
      let _ = launchBombs(); 
      let _ = applyThrust();

      tick := tick + 1;
      if (tick > 3600) { 
        endGame();
      };
      return #Ok;
    };

    public func move(l : List.List<T.GameObject>) : List.List<T.GameObject> {
      return List.map<T.GameObject, T.GameObject>(l, doPhysics);
    };

    public func cleanup(l : List.List<T.GameObject>) : List.List<T.GameObject> {
      return List.filter<T.GameObject>(l, func go {
        return (not go.cleanup);
      });
    };

    func applyThrust() : T.Result {
      ships := List.map<T.GameObject, T.GameObject>(ships, func (s) {
        switch (List.find<T.InputCommand>(thrustIntents, func cmd { cmd.player == s.id })) {
          case (null) { 
            return s;
          };
          case (?inputCommand) {
            let maxThrust = 0.01; // getNat(s.id, ".ship.maxThrust");
            return( {
              s with
                physicalPresence = { 
                   radius=s.physicalPresence.radius;
                   inertialState = {
                  s.physicalPresence.inertialState with
                    acceleration = {
                     x = maxThrust * inputCommand.vector.x;
                     y = maxThrust * inputCommand.vector.y;
                    };
                   };
                 };
             });
           //let _ = makeBomb(go, inputCommand);
         };
        };
      });
      thrustIntents := List.nil<T.InputCommand>();
      return #Ok;
    };

    public func distance (position1: T.Vector, position2 : T.Vector) : Float {
      let result : Float = Float.sqrt((position1.x - position2.x)**2 + (position1.y - position2.y)**2);
      return(Float.abs(result));
    };

    public func doPhysics(o : T.GameObject) : T.GameObject {
      let t = 100.0;
      var velocity = o.physicalPresence.inertialState.velocity;
      var acceleration = o.physicalPresence.inertialState.acceleration;
      var position = o.physicalPresence.inertialState.position;

      position := {
        x = position.x + (velocity.x * t) + (0.5 * acceleration.x * t*t);
        y = position.y + (velocity.y * t) + (0.5 * acceleration.y * t*t);
      };
      //Out of bounds wraparound
      if (position.x > 800) {
        position := { x = position.x - 800.0;
                      y = position.y}
      };
      if (position.y > 600) {
        position  := { x = position.x;
                      y = position.y - 600.0}
      };
      if (position.x < 0) {
        position := { x = position.x + 800.0;
                      y = position.y}
      };
      if (position.y < 0) {
        position  := { x = position.x;
                      y = position.y + 600.0}
      };

      velocity := {
        x = velocity.x + (acceleration.x * t);
        y = velocity.y + (acceleration.y * t);
      };

      return( {
        o with 
         physicalPresence = 
         {o.physicalPresence with
            inertialState = { o.physicalPresence.inertialState with
                position = position;
                velocity = velocity;
                acceleration = {x = 0.0; y = 0.0;}
              };
          };
      });
    };

    public func status() : async T.GameStatus {
      return gameStatus;
    };

    public func getGameView() : async T.BDBView {
      let gos = List.append<T.GameObject>(ships, bombs);
      var dataKeys =  List.nil<Text>();
      var dataValues =  List.nil<Nat>();
      for ((k, v) in natData.entries()) {
        dataKeys := List.push<Text>(k, dataKeys);
        dataValues := List.push<Nat>(v, dataValues);
      };
      let view : T.BDBView = {
        status = gameStatus;
        objects = List.toArray<T.GameObject>(gos);
        dataKeys = List.toArray<Text>(dataKeys);
        dataValues = List.toArray<Nat>(dataValues);
        tick = tick;
      };
    };

    public func verifyPrincipal(principal: Principal, playerID: Nat) : async T.Result {
      switch (principals.get(playerID)) {
        case (?foundPrincipal) {
            if (foundPrincipal == principal) {
              return #Ok;
            };
            return #Err;
        };
        case (null) {
           return #Err;
        };
      };
    };

    public func processInputCommand(playerID: Nat, inputCommand: T.InputCommand) : async T.Result {
       if (getNatForID(playerID, ".ship.health") == 0) {
          return #Ok;
       };
       switch (inputCommand.commandType) {
         case (#Thrust) {
           thrustIntents := List.push<T.InputCommand>(inputCommand, thrustIntents);
         };
         case (#Fire) {
            fireIntents := List.push<T.InputCommand>(inputCommand, fireIntents);
         };
         case (#None) {
         };
       };
       return #Ok;
    };

    public func getShip(playerID: Nat) : ?T.GameObject {
      return List.find<T.GameObject>(ships, func s { s.id == playerID });
    };

    func gameTick() : async () {
      let _ = await mainLoop();
    };
    timerID := Timer.recurringTimer(#seconds (5), gameTick);

    public func getTick(): async Nat {
      return tick;
    };

    public func getScores() : async [T.QueueEntry] {
      return (queue);
    };

    principals.put(makeShip(150.0, 100.0), queue[0].player);
    principals.put(makeShip(650.0, 100.0), queue[1].player);
    principals.put(makeShip(150.0, 500.0), queue[2].player);
    principals.put(makeShip(650.0, 500.0), queue[3].player);

  };
}
